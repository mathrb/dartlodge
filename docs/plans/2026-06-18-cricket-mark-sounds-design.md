# Cricket mark sounds — Design

**Date:** 2026-06-18
**Status:** Validated (brainstorm)
**Scope:** First slice of the v2 sound backlog (design `2026-06-16-sounds-design.md` §6) — cricket per-mark tick sounds. Builds on the shipped v1 epic #516.

---

## 1. Goal

Give cricket darts mark-specific audio feedback (like a bar cricket machine) using the two
clips already on disk: `cricketSingleMark.wav`, `cricketTripleMark.wav`. Replaces the generic
`dartHit`/`dartMiss` mapping for the cricket board only; the other three boards are unchanged.

## 2. Per-dart decision (validated)

Keyed on **marks actually scored** by the dart, not the physical multiplier — robust to the
3-mark cap, overflow, and all target modes (fixed/random/crazy).

Two facts diffed from before/after state, gated on the same "real new dart" signal as v1
(`dartsThrownInTurn` +1 on the same competitor — otherwise no sound):

- **marksAdded** = `sum(activeCompetitor.marksPerNumber.values)` delta (∈ 0..3; Bull is a key
  in `marksPerNumber`, so bull marks count automatically).
- **scoredPoints** = the summed score of **all** competitors increased (covers standard —
  thrower's own score up — and cut-throat — opponents' score up; no-score variant → false).

| Case | Cue |
|---|---|
| marksAdded == 3 | `cricketTripleMark` |
| marksAdded ∈ {1, 2} | `cricketSingleMark` (no dedicated "double" clip) |
| marksAdded == 0, scoredPoints | `dartHit` |
| marksAdded == 0, no points (true miss / off-target / closed no-score) | `dartMiss` |

## 3. Architecture

**Seam (`core/`)** — extend the shared vocabulary:
`SoundCue { dartHit, dartMiss, bust, cricketSingleMark, cricketTripleMark }`
(`lib/core/sound/sound_cue.dart`).

**Service (`features/sound`)** — `SoundService._assets` maps the two new cues to
`sounds/cricketSingleMark.wav` / `sounds/cricketTripleMark.wav`. `allAssets` (preload) picks
them up automatically. No decision logic in the service.

**Domain (`features/game`) — pure, testable:**
`lib/features/game/domain/sound/cricket_mark_signal.dart`
```dart
({int marks, bool scoredPoints})? cricketDartOutcome(GameState? prev, GameState? next);
```
Same +1 guard as `newestDartSegment`; returns null when it isn't a single new dart. Imports
only `game_state.dart` — no `core/sound` coupling (returns facts, not a `SoundCue`).

**Presentation (`features/game`) — wiring:**
`wireCricketSounds(ref, provider, {required gameStateOf})` in
`lib/features/game/presentation/sound/wire_game_sounds.dart` maps the facts → `SoundCue`
(table §2) and calls `sound.play(cue)`. The generic `wireGameSounds<T>` is unchanged for the
other three boards. `cricket_board_page.dart` swaps its `wireGameSounds(...)` call for
`wireCricketSounds(...)`.

**Assets:** commit `assets/sounds/cricketSingleMark.wav` + `cricketTripleMark.wav` (currently
untracked). `assets/sounds/` is already declared in `pubspec.yaml`.

## 4. Layering

`domain/` stays pure (returns facts, no `core/sound` import). The board reaches sound only via
the `core/` seam — no feature imports another. Decision (facts→cue) lives in game presentation;
the sound feature only maps cue→asset. Consistent with the v1 epic.

## 5. Testing

- **Unit** `cricket_mark_signal_test.dart`: single (1), double (2), triple (3), cap (triple on
  a number with 2 marks → +1 → single), closed-number points (0 marks + score↑ → `scored:true`),
  true miss (0/0), cut-throat (opponent score↑ → scored), not-a-new-dart (null), MISS segment.
- **Widget** `cricket_board_page_test.dart`: spy `SoundPort`; drive transitions and assert
  `cricketSingleMark` / `cricketTripleMark` / `dartHit` / `dartMiss`. Update the existing
  cricket "dart sound" test (it asserted `dartThrown('T20')`, which no longer applies — cricket
  no longer calls `dartThrown`).

## 6. Out of scope

X01 dedicated T20 sound, practice cues, the segment caller, `achievementUnlock` — remain in the
v2 backlog. No "double mark" clip (double shares the single tick).
