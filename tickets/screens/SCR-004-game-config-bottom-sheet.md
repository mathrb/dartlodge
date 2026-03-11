# SCR-004 — Game Config Bottom Sheet

**Route:** `/game/config` (modal bottom sheet — not a full page)
**File:** `lib/features/game/presentation/pages/game_config_page.dart`

---

## Design Principles

- **P2 — APPLY action reachable from thumb position:** The APPLY SETTINGS button is anchored at the bottom of the sheet, always visible and in comfortable thumb reach.
- **P4 — Clean form layout:** No decorative chrome. Fields are directly labeled, minimal nesting.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│         ────                │  ← drag handle: 4dp tall × 32dp wide visual bar
│                             │    48×48dp centered tap target above/including bar
│  Game Settings              │  ← sheet title (textHeadingMedium)
├─────────────────────────────┤
│  Starting Score             │  ← field label (textBodyMedium, colorOnSurfaceVariant)
│  [501 ▾]                    │  ← dropdown control
│                             │
│  In Strategy                │
│  [Any ▾]                    │
│                             │
│  Out Strategy               │
│  [Double ▾]                 │
│                             │
│  Legs to Win                │
│  [−]  3  [+]                │  ← stepper: two icon buttons flanking a value
├─────────────────────────────┤
│  [    APPLY SETTINGS    ]   │  ← full-width FilledButton
│  (SafeArea bottom padding)  │
└─────────────────────────────┘
```

**Zone descriptions:**

- **Drag handle:** Visual bar is 4dp tall × 32dp wide, `colorOutline`, rounded `radiusFull` (9999dp), centered horizontally. The tappable area is a 48×48dp centered region over and including the visual bar — tapping the handle dismisses the sheet without saving.
- **Sheet title:** "Game Settings" in `textHeadingMedium`. `space6` (24dp) top padding from drag handle. `space4` (16dp) horizontal margin.
- **Form fields:** Each field occupies its own row. Field label above the control, with `space4` (16dp) between label top and the previous field's control bottom. `space4` (16dp) horizontal margin throughout.
- **Legs to Win stepper:** Consists of a "−" outlined IconButton (minimum 48×48dp), a centered count value, and a "+" outlined IconButton (minimum 48×48dp). The three elements are in a horizontal row with the count centered between the buttons.
- **APPLY SETTINGS:** Full-width FilledButton, `space4` (16dp) horizontal margin, `space4` (16dp) top padding from last field, wrapped in SafeArea for bottom inset.

---

## Typography

| Element | Token | Color |
|---|---|---|
| Sheet title "Game Settings" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Field labels (Starting Score, In Strategy, etc.) | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurfaceVariant` |
| Dropdown selected value | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` |
| Stepper count value | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| "APPLY SETTINGS" button label | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |

---

## Colors

| Element | Token |
|---|---|
| Sheet background | `colorSurface` |
| Drag handle visual bar | `colorOutline` |
| Dropdown container background | `colorSurfaceVariant` |
| Dropdown container corner radius | `radiusSmall` (8dp) |
| Dropdown trailing arrow icon | `colorOnSurfaceVariant` |
| Stepper "−" button border | `colorPrimary` |
| Stepper "−" button text/icon | `colorPrimary` |
| Stepper "+" button border | `colorPrimary` |
| Stepper "+" button text/icon | `colorPrimary` |
| Stepper button (disabled) | foreground at 38% opacity, border `colorOutlineVariant` |
| "APPLY SETTINGS" background | `colorPrimary` |
| "APPLY SETTINGS" text | `colorOnPrimary` |

---

## Interactions

- **Sheet height:** `isScrollControlled: true`. Maximum height is 75% of screen height. If content is shorter, the sheet sizes to fit. The sheet is scrollable if content exceeds 75% of screen height.
- **Drag handle tap (48×48dp region):** Dismisses the sheet without saving changes.
- **Drag handle swipe down:** Dismisses the sheet without saving changes.
- **Tapping outside the sheet (scrim):** Dismisses the sheet without saving changes.
- **Dropdown (Starting Score):** Values: 101, 170, 201, 301, 401, 501, 701, 1001. Default selected: 501.
- **Dropdown (In Strategy):** Values: Any, Double, Master (Double or Triple). Default: Any.
- **Dropdown (Out Strategy):** Values: Any, Double, Master. Default: Double.
- **Stepper (−) button:** Minimum 48×48dp. Decrements Legs to Win by 1. Disabled when value is 1.
- **Stepper (+) button:** Minimum 48×48dp. Increments Legs to Win by 1. Disabled when value is 9.
- **All changes:** Held in local ephemeral state within the bottom sheet. No changes propagate until APPLY is tapped.
- **"APPLY SETTINGS":** Applies all changes to the GameSetupState, dismisses the sheet, and causes the config summary chip on the Player Selection screen to update immediately.

---

## Edge Cases

- **Practice games:** No configurable fields exist. The sheet shows only the title "Game Settings" and the APPLY button with no fields in between. Alternatively, the config chip on Player Selection may choose not to open the sheet at all for practice game types — implementation decision.
- **Cricket game type fields:**
  - Variant: Dropdown with values "Standard", "Cut-Throat". Default: Standard.
  - Points to Win: Stepper. Min 1, max 9. Default: 3.
  - (No Starting Score, In Strategy, Out Strategy, or Legs to Win for Cricket.)
- **Stepper bounds:**
  - Legs to Win minimum: 1. The "−" button is disabled when value equals 1.
  - Legs to Win maximum: 9. The "+" button is disabled when value equals 9.
  - Disabled stepper buttons: foreground at 38% opacity; border color `colorOutlineVariant`.

---

## Special Notes

- This sheet is opened **exclusively** from the config summary chip on the Player Selection page (SCR-003). It is not a route that can be pushed independently.
- The sheet is not full-screen. It is a true bottom sheet that overlays the Player Selection page with a scrim behind it.
- Fields shown depend entirely on the active game type. The sheet must inspect the current `GameSetupState` to determine which fields to render.
- "Master Out" means the player can finish on either a double or a triple (in standard darts parlance). Label it "Master" in the dropdown.
- Drag handle corners: `radiusFull` (pill-shaped).
- Sheet corner radius at top: `radiusXLarge` (24dp) on top-left and top-right corners; bottom corners `radiusNone`.
