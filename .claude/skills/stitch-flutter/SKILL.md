# stitch-flutter

Convert a Stitch-designed screen into a Flutter widget for this project.

**Usage:** `/stitch-flutter <screenId>` — or omit the screen ID to list available screens.

---

## Execution

Follow every step in order. Do not skip steps or reorder them.

### Step 1 — Discover

If `$ARGUMENTS` is empty or the user did not provide a screen ID:

1. Call `mcp__stitch__list_projects` to list all Stitch projects.
2. For the relevant project, call `mcp__stitch__list_screens` to show all screens.
3. Present the screen names and IDs to the user and ask which screen to convert.
4. Stop here and wait for the user to provide a screen ID before continuing.

If `$ARGUMENTS` contains a screen ID, continue to Step 2 immediately.

---

### Step 2 — Fetch

Call `mcp__stitch__get_screen` with the screen ID from `$ARGUMENTS`.

Extract from the response:
- `htmlCode` — the rendered HTML/CSS of the screen (contains layout, colors, spacing, typography)
- `screenshot.downloadUrl` — visual reference (optional, for your understanding)
- The screen's name/title

Also read these project files now so you have them in context:
- `lib/core/utils/app_text_styles.dart`
- `lib/core/utils/app_theme.dart`
- `lib/core/utils/app_colors.dart`

---

### Step 3 — Classify

Before writing any code, determine:

**a) Widget class** — pick exactly one:

| Use case | Class |
|---|---|
| Pure display, no Riverpod state | `StatelessWidget` |
| Reads providers, no lifecycle | `ConsumerWidget` |
| Reads providers + has animations / controllers / listeners | `ConsumerStatefulWidget` |

Full pages always use `Scaffold` as their root. Sub-components do not.

**b) File path** — pick exactly one:

| Type | Path |
|---|---|
| Full screen / route | `lib/features/<feature>/presentation/pages/<snake_name>_page.dart` |
| Reusable component | `lib/features/<feature>/presentation/widgets/<snake_name>_widget.dart` |

If the correct `<feature>` folder is ambiguous, ask the user before writing the file.

---

### Step 4 — Map design tokens

When translating the Stitch HTML into Flutter code, apply this mapping without exception:

**Colors — never use hardcoded hex. Always use `Theme.of(context).colorScheme`.**

```
cs = Theme.of(context).colorScheme

Neon primary action / active accent  →  cs.primaryFixed          (#00FFAB)
Hover / pressed neon                  →  cs.primaryFixedDim       (#00E297)
Text on neon fills                    →  cs.onPrimaryContainer    (#002112)
Primary text                          →  cs.onSurface
Secondary / metadata text             →  cs.onSurfaceVariant
Deepest background                    →  cs.surface
Level-1 section / active player bg   →  cs.surfaceContainerLow
Level-2 interactive card              →  cs.surfaceContainer
Score input buttons                   →  cs.surfaceContainerHighest
Floating / popover                    →  cs.surfaceBright
Bust / error                          →  cs.errorContainer (bg) + cs.onErrorContainer (text)
Ghost border                          →  cs.outlineVariant at 0.20 opacity
```

For opacity: use `.withValues(alpha: 0.12)` — never `.withOpacity()` (deprecated in Flutter 3.24+).

**Typography — always use `Theme.of(context).textTheme` or `AppTextStyles`:**

```
Screen title / section header   →  tt.headlineLarge
Sub-title, stepper value        →  tt.headlineSmall
Player names (ALL CAPS)         →  tt.titleMedium
List item label                 →  tt.bodyLarge
Admin data, descriptions        →  tt.bodyMedium
Metadata, captions              →  tt.bodySmall
Button labels (ALL CAPS)        →  tt.labelLarge
Chips, tabs (ALL CAPS)          →  tt.labelMedium
Column headers, overlines       →  tt.labelSmall

Live score — active player      →  AppTextStyles.scoreActive(context)
Live score — inactive player    →  AppTextStyles.scoreInactive(context)
Post-game summary score         →  AppTextStyles.scoreMedium(context)
History / stat card score       →  AppTextStyles.scoreSmall(context)
Dart segment grid button        →  AppTextStyles.segmentButton(context)
```

Use `.copyWith()` for local overrides. Never build a `TextStyle(...)` from scratch for theme styles.

**Spacing — 4dp base grid only. Use `const SizedBox` or `EdgeInsets` with these values:**

```
4dp   space1  — icon gaps, tight chip padding
8dp   space2  — compact padding, list tile vertical
12dp  space3  — gap between list items (no dividers)
16dp  space4  — standard page margins, content padding
20dp  space5  — card internal padding top/bottom
24dp  space6  — section spacing within screen
32dp  space8  — section headers
40dp  space10 — large visual break
48dp  space12 — empty state illustration margin
64dp  space16 — bottom scroll padding, admin top padding
```

**Radius — stick to the extremes; never 4dp or 8dp:**

```
Match board elements  →  AppTheme.radiusNone   (0)    — sharp, zero radius
Admin cards           →  AppTheme.radiusLarge  (16)
Admin primary buttons →  AppTheme.radiusXLarge (24)
Pills / chips         →  AppTheme.radiusFull   (9999)
```

**Gradient card (Admin / Home screens):**

```dart
decoration: AppTheme.kineticCardDecoration()
```

**Interactive elements:**

All tappable surfaces use `InkWell` (not `GestureDetector`) to provide Material ripple:

```dart
InkWell(
  onTap: onTap,
  splashColor: const Color(0x0D00FFAB),
  highlightColor: const Color(0x0D00FFAB),
  child: ...,
)
```

Minimum tap target: 48×48dp. Wrap smaller icons in `SizedBox(width: 48, height: 48)` with `IconButton` or align with `Align`.

**Design principles — enforce all three:**

- **P1 No-Line Rule:** No standard 1px borders. Use tonal background shifts or negative space instead. Ghost borders (`outlineVariant` at 20% opacity) are allowed only on cards.
- **P2 Sharp/Soft Hybrid:** Zero radius (`radiusNone`) in Match Board screens only. Use `radiusLarge`/`radiusXLarge`/`radiusFull` everywhere else.
- **P3 State Always Visible:** In game screens — active player, current score, darts thrown, remaining outs must all remain visible simultaneously.

---

### Step 5 — Generate

Write the Flutter widget file. Use this template as your scaffold:

```dart
// Copyright notice if needed

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // only if ConsumerWidget

// Import only what this widget directly uses.
// Never import from another feature's folder.
// Never import from domain/ or data/ layers.

class StitchScreenWidget extends StatelessWidget { // ← swap class as determined in Step 3
  const StitchScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return /* your widget tree here */;
  }
}
```

Rules while writing:
- Use `const` constructors wherever possible (compile-time constant subtrees).
- Extract logical sub-sections into private `_SectionName` `StatelessWidget` classes within the same file to keep `build()` readable.
- Player names render in ALL CAPS: `player.name.toUpperCase()`.
- Button labels render in ALL CAPS.
- Score numerals must never truncate; constrain the container, not the `Text` widget.
- If the screen has a `Scaffold`, set `body: SafeArea(child: ...)` and add appropriate `padding`.
- No `Divider()` widgets — use spacing instead (P1).

---

### Step 6 — Validate

Before presenting the code to the user, run this checklist mentally. Fix every failing item.

**Structure**
- [ ] No hardcoded hex colors anywhere in the file
- [ ] No hardcoded pixel sizes outside the 4dp spacing scale
- [ ] No imports from another feature's folder (`lib/features/<other>/...`)
- [ ] No imports from `domain/` or `data/` inside a widget/page file
- [ ] `const` used wherever the subtree is compile-time constant

**Theming**
- [ ] All colors via `cs.*` (where `cs = Theme.of(context).colorScheme`)
- [ ] All text styles via `tt.*` or `AppTextStyles.*` with `.copyWith()` for overrides
- [ ] `.withValues(alpha: x)` used for opacity (not `.withOpacity()`)

**Interaction**
- [ ] Every tappable surface uses `InkWell` with `splashColor` and `highlightColor` set
- [ ] Minimum 48×48dp tap target on all interactive elements

**Riverpod** (only if `ConsumerWidget` / `ConsumerStatefulWidget`)
- [ ] `ref.watch()` called only inside `build()`
- [ ] `ref.read()` called only in callbacks/methods
- [ ] All `AsyncValue` results handle `data`, `loading`, and `error`

**Accessibility**
- [ ] All `Icon` widgets have a `semanticsLabel`
- [ ] Decorative images set `excludeFromSemantics: true`

If any item fails, fix the code before delivering it.

---

### Step 7 — Deliver

1. Write the file to the path determined in Step 3 using the Write tool.
2. Tell the user the file path.
3. If the file contains `@riverpod` or `@freezed` annotations, remind the user to run:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Suggest running `flutter analyze lib/features/<feature>/presentation/` to verify zero errors.
