# TICKET-021: Home Page + GameCardWidget

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Implement the app's entry point: a home screen with a 2×2 grid of primary game cards and three full-width feature cards below. Wrap the home screen (and future History, Stats, Settings screens) in a `ShellRoute` with a `BottomNavigationBar`. Change `GoRouter`'s `initialLocation` from `/players` to `/`.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/pages/home_page.dart` created as `ConsumerWidget`
- [ ] `lib/features/game/presentation/widgets/game_card_widget.dart` created as `StatelessWidget`
- [ ] `GoRouter.initialLocation` set to `'/'` in `lib/app/app_router.dart`
- [ ] `ShellRoute` (or `StatefulShellRoute.indexedStack`) wraps: Home (`/`), History (`/history`), Stats (`/stats`), Settings (`/settings`)
- [ ] `BottomNavigationBar` has 4 tabs: Home, History, Stats, Settings
- [ ] Home page layout:
  - `GridView.count(crossAxisCount: 2, childAspectRatio: 1.0)` for the 4 primary cards
  - X01 card: label "X01", color `Color(0xFFC62828)`
  - Cricket card: label "Cricket", color `Color(0xFF00897B)`
  - Practice card: label "Practice", color `Color(0xFFF57C00)`
  - Stats card: label "Statistics", color `Color(0xFF7B1FA2)`
  - 3 full-width stub cards below the grid: "Game Lobby", "VS Friends", "Bluetooth" (disabled / greyed out, no tap action)
- [ ] `GameCardWidget` accepts: `String label`, `Color color`, `IconData icon`, `VoidCallback? onTap`
  - Tapping an active card calls `ref.read(gameSetupProvider.notifier).selectGameType(type)` then `context.push('/game/variant-selection')`
  - Disabled cards (null `onTap`) render at reduced opacity (0.5)
- [ ] History, Stats, and Settings routes show a placeholder `Scaffold` with a centred "Coming soon" text — no functional implementation required this epic
- [ ] All existing `/players` routes from EPIC-002 remain accessible under the shell or as modal routes

---

## Files

- `lib/features/game/presentation/pages/home_page.dart` — **to create**
- `lib/features/game/presentation/widgets/game_card_widget.dart` — **to create**
- `lib/app/app_router.dart` — **to update** (`initialLocation`, shell route, new home route)

---

## Implementation Notes

- `GameCardWidget` is a `StatelessWidget` because it holds no state and does not read providers — the tap callback is injected by the parent `HomePage`.
- The `ShellRoute` scaffold (with `BottomNavigationBar`) lives in a `ScaffoldWithNavBar` widget in `lib/app/` or `lib/core/widgets/`. Do not put shell logic inside `home_page.dart`.
- Icon suggestions (use `Icons.*`): X01 → `Icons.sports_cricket`, Cricket → `Icons.sports_cricket`, Practice → `Icons.track_changes`, Stats → `Icons.bar_chart`. Adjust to available icons.
- The stub feature cards ("Game Lobby" etc.) are `ListTile` or custom `Card` widgets with `enabled: false`. They must not crash if tapped.
- Tapping the Stats card navigates to `/stats` (the shell tab), not to the game setup flow.
- Do not implement the History, Stats, or Settings pages in this ticket — stub `Scaffold`s are sufficient.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Home Screen", §"Bottom Navigation".

---

