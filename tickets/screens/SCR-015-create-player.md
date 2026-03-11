# SCR-015 — Create Player Page

**Route:** `/players/add`
**File:** `lib/features/players/presentation/pages/create_player_page.dart`

---

## Design Principles

- **P4 — Minimal form, clear action:** A single text field and a single primary button. No unnecessary fields or decoration.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "New Player"    ←  │
├─────────────────────────────┤
│                             │
│                             │
│          [  ○  ]            │  ← 60dp circular avatar preview (centered)
│    (initials update as you  │
│     type in the name field) │
│                             │
│  ┌─────────────────────────┐│
│  │  Name                   ││  ← text field with floating label
│  └─────────────────────────┘│
│    Character counter        │  ← appears at 80% of max (19+ chars); e.g. "19/24"
│    Validation error         │  ← appears below field on invalid input
│                             │
│  [    CREATE PLAYER    ]    │  ← full-width FilledButton
│                             │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow dismisses without creating. Title "New Player".
- **Avatar preview:** 60dp diameter circular avatar, centered horizontally. Renders initials (first letter of current field value, uppercased). When the field is empty, shows a generic `person` icon in `colorOnSecondaryContainer`.
- **Name text field:** Full-width with `space4` (16dp) horizontal margin. Floating label "Name". Outlined field style. Auto-focused on page open.
- **Character counter:** Shown only when input length ≥ 19 characters (80% of 24-char max). Positioned below the field, right-aligned. Format: "{length}/24".
- **Validation error:** Shown below the field when validation fails. Replaces or appears alongside the character counter.
- **CREATE PLAYER button:** Full-width with `space4` (16dp) horizontal margin. Anchored below the field with `space4` (16dp) top gap. Not anchored to the bottom of the screen — it flows below the field. If the keyboard is open, the layout scrolls to keep the button visible.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "New Player" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Name field floating label | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurfaceVariant` (unfocused) / `colorPrimary` (focused) |
| Name field input text | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` |
| Character counter | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Validation error text | `textBodySmall` (DM Sans Regular 12sp) | `colorError` |
| Avatar initials | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnSecondaryContainer` |
| "CREATE PLAYER" enabled | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| "CREATE PLAYER" disabled | `textLabelLarge` | `colorOnSurface` at 38% opacity |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Avatar preview background | `colorSecondaryContainer` |
| Avatar preview default icon | `colorOnSecondaryContainer` |
| Name field border (unfocused) | `colorOutlineVariant` |
| Name field border (focused) | `colorPrimary` (2dp) |
| Name field border (error state) | `colorError` (2dp) |
| Name field background | `colorSurface` |
| "CREATE PLAYER" enabled background | `colorPrimary` |
| "CREATE PLAYER" disabled background | `colorSurfaceVariant` |
| Character counter text | `colorOnSurfaceVariant` |
| Validation error text | `colorError` |

---

## Interactions

**Name text field:**
- Auto-focused on page open (keyboard appears immediately).
- As user types: avatar preview initials update in real time (first character of current input, uppercased).
- When field is empty: avatar shows generic `person` icon (not initials).
- Max 24 characters: field does not accept additional input once 24 chars are reached. Counter shows "24/24".
- Character counter appears at length 19 (= 80% of 24 rounded up to nearest integer). Hidden below 19 chars.

**Field validation triggers:**
- On "CREATE PLAYER" button tap (primary validation moment).
- On field unfocus (secondary, less disruptive): only show error if the field is non-empty and fails uniqueness check.
- Do NOT show "A player named X already exists" while the user is still typing.

**"CREATE PLAYER" button:**
- Disabled when the field is empty. Tooltip "Enter a name" when disabled.
- Disabled if the field has a known validation error (e.g. duplicate name detected on previous attempt).
- Enabled as soon as the field has any non-empty content (uniqueness is checked only on tap, not on every keystroke).
- On tap:
  1. Show 20×20 spinner replacing the button text (async operation visual feedback).
  2. Check uniqueness against existing players.
  3. If unique: create player, dismiss page (pop), return created player data to caller.
  4. If duplicate: hide spinner, restore button text, show inline validation error below field: "A player named {name} already exists".
  5. If other error: hide spinner, show snackbar in `colorErrorContainer` bg.

**Back button:**
- Dismisses without creating. No confirmation dialog needed (no data was written).

---

## Edge Cases

**Empty name:**
- Button disabled. No error shown until user attempts to tap CREATE PLAYER with an empty field.
- After a tap attempt with empty field: show validation error "Name is required".

**Duplicate name:**
- Inline error below field: "A player named {name} already exists".
- Field border changes to `colorError` (2dp).
- Floating label changes to `colorError`.
- Button remains disabled until the user modifies the field value.

**Name exactly at max (24 chars):**
- Character counter shows "24/24" in `colorError` to signal the limit is reached.
- No additional characters accepted.
- Button remains enabled (24 chars is valid).

**Keyboard obscuring the button:**
- The page content should scroll so the CREATE PLAYER button remains visible above the keyboard. Use a `SingleChildScrollView` or equivalent.

---

## Special Notes

- **This page doubles as an inline modal from the Player Selection roster "+" card (SCR-003):**
  - In that context, the page is presented as a bottom sheet or dialog (not a full-page push route).
  - On success: created player auto-appears in the roster grid and is auto-selected (moved to the selected-player area).
  - The same page widget is reused. A parameter (e.g. `isModal: true`) controls whether it shows as a full page or a modal overlay.
- **Avatar preview diameter:** 60dp (smaller than the 80dp on Player Detail — this is a preview context).
- **Field corner radius:** `radiusSmall` (8dp) for the outlined field container.
- Page horizontal margin: `space4` (16dp).
- Avatar is centered with `space8` (32dp) top padding from the AppBar bottom, and `space6` (24dp) bottom padding before the field.
