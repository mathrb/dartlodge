# Sound effects — Design

**Date:** 2026-06-16
**Status:** Validated (design phase) — issues not yet created
**Epic scope:** v1 — play sound effects on game moments behind a reusable audio seam. Caller / extended cues = a later v2 epic.

---

## 1. Goal & scope

Play short sound effects on key game moments, behind a seam that a future **achievements** epic can reuse (unlock → sound). The audio seam is the real deliverable; v1 ships a small, high-impact cue set.

**v1 cues:** `dartHit`, `dartMiss`, `bust`.

**Explicitly NOT done (not even v2):** `legWin`, `gameWin`, `turnStart`, `crazyTargetsRolled`.

**Current state:** only `assets/sounds/hit.mp3` exists; `assets/sounds/` is not declared in `pubspec.yaml`; no audio package present. Observable state signals (verified): `gameState.dartsThrownInTurn`/current-turn darts (last segment), `showBust` (X01 + Catch-40), `pendingLegWinnerId`, `pendingGameWinnerId`, `isComplete`.

---

## 2. Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| v1 cue set | `dartHit`, `dartMiss`, `bust` | High-impact, low noise. |
| Effects vs caller | **Layered** (option 2) | Global sound on/off + an independent "Announce segments" toggle (v2) that stacks. Default behaviour when both on: both play (thunk + voice). A "voice replaces thunk" tuning may be revisited later. |
| Caller (segment readout) | **v2**, pre-recorded **composed English clips**, EN only | "Like electronic dartboards in bars." ~24 clips: `double`, `treble`, `1…20`, `bull`(25), `bullseye`(50), `miss`. "Treble 20" = `treble.mp3` + `twenty.mp3`. No localization (frozen EN pack), decoupled from the i18n epic. |
| Audio package | **`audioplayers`** | Plays on web + mobile with **zero special headers** (GitHub Pages / dev target intact); covers SFX + sequential caller; simplest API; latency is fine for sparse darts SFX. |
| Web behaviour | Real impl on web + mobile; **no-op in tests** via the default `core/` port (no override needed) | audioplayers is cross-platform → no `if (dart.library.io)` conditional import. |
| Trigger point | Presentation `ref.listen` on the active-game provider's derived state | Mirrors the existing `showBust → snackbar` listener; keeps `domain/` Flutter-free; not the raw `GameEvent` stream (not the project's pattern). |
| Global sound default | **ON** | A discreet dart thunk is expected. |
| Seam shape | `core/` port with a **no-op default**, overridden at the composition root | Mirrors `boardOverlayBuilder`; tests get the no-op for free. |

### Audio package alternatives considered (2025-2026 research)

- **`flutter_soloud`** — the textbook "game audio" answer (official Flutter codelab, lowest latency). **Rejected**: its only real edge (ultra-low latency for *massively* simultaneous SFX) is irrelevant to sparse darts SFX, while its web mode needs **cross-origin isolation (COOP/COEP)** — on GitHub Pages that forces the `coi-serviceworker` hack, fragilizing web deployment. Bad trade here.
- **`just_audio`** — Flutter Favorite, gapless `ConcatenatingAudioSource` (great for the v2 caller), good web support without special headers. Heavier; needs a pool for rapid SFX. May be re-evaluated for the v2 caller mode only — without touching the seam (the `SoundPlayer` interface abstracts the package).
- **`soundpool`** — low-latency SFX but weak/absent web support, no easy sequencing. Poor fit.

Refs: [Flutter SoLoud codelab](https://codelabs.developers.google.com/codelabs/flutter-codelab-soloud), [flutter_soloud pub](https://pub.dev/packages/flutter_soloud), [coi-serviceworker (GitHub Pages COOP/COEP)](https://github.com/gzuidhof/coi-serviceworker), [just_audio](https://pub.dev/packages/just_audio), [Flutter Gems — audio](https://fluttergems.dev/audio/).

---

## 3. Architecture

### 3.1 The seam — `core/sound/`

Mirrors the `boardOverlayBuilder` pattern (a `core/` provider with a no-op default, overridden at the composition root). No `bind/bump` dance; tests get the no-op automatically.

```
lib/core/sound/
  sound_cue.dart            # enum SoundCue { dartHit, dartMiss, bust }  (pure Dart)
  sound_port.dart           # interface called by game / future achievements
  sound_port_provider.dart  # default = no-op
```

Contract — two entry points:
```dart
abstract interface class SoundPort {
  void play(SoundCue cue);          // generic cues: bust (+ future achievementUnlock)
  void dartThrown(String segment);  // e.g. 'T20', 'MISS' — the service maps hit/miss
}
```
> `dartThrown(segment)` (not `play(dartHit)`/`play(dartMiss)` at the call site): the board just **reports the dart**; the service maps segment→cue. This makes v2 **additive without touching call sites** — the caller (announce segment), the dedicated T20 sound, and cricket mark-ticks all live in the service, keyed off `segment`.

Default provider (no-op, no plugin → safe in tests by default):
```dart
@riverpod
SoundPort soundPort(Ref ref) => const _NoopSoundPort();
class _NoopSoundPort implements SoundPort {
  const _NoopSoundPort();
  void play(SoundCue cue) {}
  void dartThrown(String segment) {}
}
```

`core/` carries only a contract + a no-op (no domain logic, no plugin). `SoundCue` is a shared entity. No feature imports another: game and (later) achievements know only `soundPortProvider`. The real impl lives in `sound/` and is injected at the root.

### 3.2 Implementation — `features/sound/`

```
lib/features/sound/
  domain/sound_player.dart                       # low-level: plays an asset
  data/audioplayers_sound_player.dart            # audioplayers impl (web + mobile)
  presentation/providers/sound_settings_provider.dart   # toggle(s)
  presentation/providers/sound_service.dart      # SoundService implements SoundPort
```

`SoundPlayer` (low-level, decouples the service from the package):
```dart
abstract interface class SoundPlayer {
  Future<void> preload(Iterable<String> assets);
  Future<void> play(String asset);
  Future<void> dispose();
}
```
`AudioPlayersSoundPlayer` (data): `AudioPool`/`AudioPlayer` in `PlayerMode.lowLatency`, assets preloaded at startup. Every playback error is swallowed (`try/catch`) — a failed sound must never disrupt scoring (same rule as auto-scorer captures).

`SoundService implements SoundPort` — receives `Ref`, reads settings at play time, maps cue→asset:
```dart
class SoundService implements SoundPort {
  SoundService(this._ref, this._player);
  static const _assets = {
    SoundCue.dartHit: 'assets/sounds/hit.mp3',
    SoundCue.dartMiss: 'assets/sounds/miss.mp3',
    SoundCue.bust: 'assets/sounds/bust.mp3',
  };
  void play(SoundCue cue) {
    if (!(_ref.read(soundEnabledProvider).value ?? true)) return; // global gate
    _player.play(_assets[cue]!);
  }
  void dartThrown(String segment) =>
      play(segment == 'MISS' ? SoundCue.dartMiss : SoundCue.dartHit);
  // v2: if segmentCallerEnabled → sequence announce clips; dedicated T20; cricket ticks
}
```

Composition-root injection (`lib/main.dart`, the only place allowed to import the feature):
```dart
soundPortProvider.overrideWith((ref) {
  final player = AudioPlayersSoundPlayer()..preload(SoundService.allAssets);
  ref.onDispose(player.dispose);
  return SoundService(ref, player);
}),
```
Web + test: the override is prod-only → sound plays on web and mobile; `flutter test` (no `main.dart`) keeps the default no-op port.

### 3.3 Settings & toggle(s)

Mirrors `DataCollectionEnabled`/`ThemeMode` (`@Riverpod(keepAlive: true)` + `SharedPreferences`).

v1 — one "global sound" toggle, **default ON**:
```dart
const _kSoundEnabledKey = 'sound_enabled';
@Riverpod(keepAlive: true)
class SoundEnabled extends _$SoundEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kSoundEnabledKey) ?? true;
  }
  Future<void> setEnabled(bool v) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kSoundEnabledKey, v);
    state = AsyncData(v);
  }
}
```
→ `soundEnabledProvider`. v2 adds an independent **"Announce segments"** toggle (key `sound_segment_caller`, default OFF, dependent on global sound) — shipped only with the v2 caller (no setting that does nothing in v1).

UI: a "Sounds" section in `settings_page.dart` with a `SwitchListTile` modeled on the existing ones. Labels are hardcoded EN here and will be localized by the i18n epic's `settings` sub-issue (#510) — no conflict.

### 3.4 Triggering — board listeners

From presentation, via `ref.listen` on the active-game provider (like the existing `showBust → snackbar` listener):
```dart
final sound = ref.read(soundPortProvider);

// dart thrown → hit/miss (detect the current-turn counter increment, read newest segment)
ref.listen(activeGameProvider(gameId).select((s) => s.value?.gameState), (prev, next) {
  final last = _newestDartSegment(prev, next); // null if no new dart
  if (last != null) sound.dartThrown(last);
});

// bust (X01 + Catch-40): false→true transition
ref.listen(activeGameProvider(gameId).select((s) => s.value?.showBust ?? false),
  (prev, next) { if (prev == false && next == true) sound.play(SoundCue.bust); });
```
- `_newestDartSegment` diffs old/new state and returns the last dart's segment for the turn (exact field — `currentTurnDarts`/equivalent — confirmed at impl). Same single observation point the v2 caller will need.
- Cricket has no `showBust` → dart signal only. Practice → dart + `showBust` (Catch-40).
- A shared helper `wireGameSounds(ref, gameId, {required hasBust})` avoids copy-paste across the 3 boards.

**Achievements reuse (future):** zero rewiring. The unlock listener will call `ref.read(soundPortProvider).play(SoundCue.achievementUnlock)` (add the enum value + asset then). The seam is ready — the point of sequencing sounds before achievements.

---

## 4. Assets & pubspec

```yaml
flutter:
  assets:
    - assets/images/
    - assets/sounds/          # new
    - assets/models/dart_auto_scorer.tflite
```
`hit.mp3` ✓ present. To source for v1: `miss.mp3`, `bust.mp3`. Missing asset → `try/catch` no-op (no crash) — infra can merge with `dartHit` alone; `miss`/`bust` activate when the files land.

## 5. Testing

- `SoundService` (unit, fake `SoundPlayer`): `dartThrown('T20')` → `hit.mp3`; `dartThrown('MISS')` → `miss.mp3`; `play(bust)` → `bust.mp3`; **sound OFF → no call** (gate).
- Default `soundPortProvider` = no-op (no override).
- Board listener (widget): override `soundPortProvider` with a spy, simulate the state transition, assert `dartThrown`/`play(bust)` called. Update board tests in the same PR.
- `flutter analyze --no-fatal-infos` green.

## 6. v2 backlog (sound shopping list)

- Composed EN caller: `double`, `treble`, `1…20`, `bull`(25), `bullseye`(50), `miss` + "Announce segments" toggle.
- X01: dedicated `T20` sound.
- Cricket: per-mark tick (single/double/treble — decide: distinct sounds vs same tick repeated ×N).
- Practice: `shanghaiBonus`, `atcAdvance`, Catch-40 / Bob's 27 milestone.
- (achievements epic): `achievementUnlock`.

## 7. Sub-issue breakdown

One epic (v1), serial (1 PR per sub-issue, `code-review` → green CI → merge). GitHub native sub-issues.

- **SI-1** — Seam: `SoundCue`/`SoundPort`/`soundPortProvider` no-op in `core/` + tests.
- **SI-2** — `SoundPlayer` + `AudioPlayersSoundPlayer` (`audioplayers` dep, preload, `try/catch`) + `SoundService` (mapping + gate) + `main.dart` override + tests.
- **SI-3** — `SoundEnabled` toggle (default ON) + "Sounds" Settings section + tests.
- **SI-4** — `wireGameSounds` on the 3 boards (dartHit/dartMiss + bust) + `pubspec` assets + `miss`/`bust` assets + board tests.

v2 (caller, T20, cricket ticks, practice) = a separate, additive epic later.

## 8. Constraints honored

- One new dependency (`audioplayers`) — justified: the stack has no audio capability.
- `core/` holds only a contract + no-op; `domain/` stays Flutter-free; no feature imports another.
- No `GameEvent` / drift for a UI preference; sounds observe derived state, not the event log.
- Branch-per-change, serial PRs, `code-review` before merge.
