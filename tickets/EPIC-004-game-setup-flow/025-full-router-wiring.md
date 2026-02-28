# TICKET-025: Full App Router + Named Route Contract

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Finalize `app_router.dart` with all routes introduced across EPIC-004 tickets (021–024), enforce a redirect guard for the player selection page, define a `GameRoutes` named-route constant class for EPIC-005/006/007 to reference, and wire stub routes for the active game boards.

---

## Acceptance Criteria

- [ ] `lib/app/app_router.dart` is the single source of truth for all GoRouter configuration
- [ ] `StatefulShellRoute.indexedStack` wraps the 4 bottom-nav tabs: `/` (Home), `/history`, `/stats`, `/settings`
- [ ] Game setup routes live **outside** the shell (no bottom nav during the setup flow):
  - `/game/variant-selection` → `VariantSelectionPage`
  - `/game/player-selection` → `PlayerSelectionPage`
- [ ] Active game board stub routes outside the shell:
  - `/game/active/x01/:gameId` → stub `Scaffold` labelled "X01 Board — coming in EPIC-005"
  - `/game/active/cricket/:gameId` → stub `Scaffold` labelled "Cricket Board — coming in EPIC-006"
  - `/game/active/practice/:gameId` → stub `Scaffold` labelled "Practice Board — coming in EPIC-007"
- [ ] Redirect guard: if a navigation attempt reaches `/game/player-selection` and `GameSetupNotifier` state is `selectingType`, redirect to `/`
- [ ] `GameRoutes` constant class defined (not instantiable):
  ```dart
  abstract final class GameRoutes {
    static const home = '/';
    static const variantSelection = '/game/variant-selection';
    static const playerSelection = '/game/player-selection';
    static const activeX01 = '/game/active/x01';
    static const activeCricket = '/game/active/cricket';
    static const activePractice = '/game/active/practice';
  }
  ```
- [ ] All EPIC-002 player routes preserved and unchanged:
  - `/players` → `PlayerListPage`
  - `/players/add` → `AddPlayerPage`
  - `/players/:id/edit` → `EditPlayerPage`
- [ ] `initialLocation` is `GameRoutes.home` (`'/'`)
- [ ] No `GoRoute` uses anonymous inline builder lambdas longer than 3 lines — extract to named builder methods or `pageBuilder` references
- [ ] `GoRouter` instance is provided via `routerProvider` (a `@riverpod` `keepAlive: true` provider) so the router can read notifier state for the redirect guard

---

## Files

- `lib/app/app_router.dart` — **to finalize** (consolidates all partial updates from tickets 021–024)

---

## Implementation Notes

- The redirect guard reads `ref.read(gameSetupProvider)` in the `redirect` callback of the `/game/player-selection` `GoRoute`. Because `gameSetupProvider` is `autoDispose`, the router must hold a reference via `ref.listen` or use `ProviderContainer` to avoid the provider being disposed while the redirect runs. The recommended approach is to make the router a `Notifier`-based provider that watches `gameSetupProvider` and updates its `redirect` closure accordingly.
- `StatefulShellRoute.indexedStack` requires a `navigatorKey` per branch. Define 4 `GlobalKey<NavigatorState>` constants at the top of `app_router.dart`.
- The `ScaffoldWithNavBar` shell widget reads the current branch index from `StatefulNavigationShell` and passes it to `BottomNavigationBar.currentIndex`. Tab changes call `navigationShell.goBranch(index)`.
- Stub active game board pages must accept a `:gameId` path parameter (they will be replaced in EPIC-005/006/007) — define them as `GoRoute(path: '/game/active/x01/:gameId', ...)`.
- EPIC-005 will replace the X01 stub route. `GameRoutes.activeX01` provides the stable constant so EPIC-005 can reference it without touching the router structure.
- Do not add redirect guards for variant selection or home — these pages are always reachable.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Navigation Structure", §"Route Guards".

---

