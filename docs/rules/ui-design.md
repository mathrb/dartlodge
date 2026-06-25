# UI, design tokens & navigation rules

> Loaded on demand. CLAUDE.md's Rules Index points here before touching UI, design tokens, game-config UI, or navigation.

### Game config is edited in a bottom sheet, not a page
X01/Cricket in/out strategy, legs-to-win, and starting score are set via the config-summary chip → `GameConfigPanel` bottom sheet on the player-selection screen (`APPLY` commits). `GameConfigPage` exists but is unwired (and there is no "Custom" variant tile — it was removed pre-1.0, #684). The `LEGS TO WIN` `ConfigStepperWidget` +/- icon buttons carry localized `semanticLabel`s (`setupLegsIncrement`/`setupLegsDecrement`, #666 fixed); the X01 config-summary chip surfaces `legsToWin` as a localized `setupLegsCount` segment, matching Cricket (#667 fixed). (E2E driving notes: `docs/E2E_REGRESSION.md` § Authoring specs.)

### Colors
Always use themed color tokens from `docs/design/DESIGN_SYSTEM.md`. Never hardcode color values directly in widgets.

### DESIGN_SYSTEM specifics the review repeatedly catches
inactive/opponent score numerals use `cs.onSurfaceVariant` (active = `onSurface`, practice target = `primary`); `label-sm` over-line above a hero numeral uses `primaryFixed` (not `onSurfaceVariant`); game-board player names = `labelMedium` ALL-CAPS `letterSpacing: 1.2`; score numerals never scale/wrap — constrain the container, never wrap a score in `FittedBox(scaleDown)`.

### Navigation — `context.go()` vs `context.push()`
`context.go()` REPLACES the entire route stack — Android's physical back button then has nothing to pop and exits the app. Use `context.push()` for any forward navigation that should be back-poppable (Home → Stats/History/Players/Settings, list → detail, etc.). Reserve `context.go()` for intentional stack resets: game completion → home, post-deletion redirects, deep-link landing pages. If a screen MUST be reached via `go()` (e.g. the variant selection flow), wrap its body in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go(GameRoutes.home); })` like `variant_selection_page.dart` does, so the Android back button still works.
