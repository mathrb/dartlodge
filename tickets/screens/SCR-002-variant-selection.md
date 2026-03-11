# SCR-002 — Variant Selection Page

**Route:** `/game/variant-selection/:gameType`
**File:** `lib/features/game/presentation/pages/variant_selection_page.dart`

---

## Design Principles

- **P2 — Single tap advances:** Tapping a variant card immediately navigates forward to Player Selection — no intermediate "confirm" button required.
- **P4 — Clean list layout:** Minimal decoration; variant names and subtitles carry all information without chrome.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "[Game Type]"   ←  │  ← e.g. "X01", "Cricket", "Practice"
├─────────────────────────────┤
│                             │
│  ┌────────────────────────┐ │
│  │ 501 — Double Out       │ │  ← variant card (selected state shown here)
│  │ Double Out · 1 Leg     │ │  ← subtitle
│  └────────────────────────┘ │
│                             │
│  ┌────────────────────────┐ │
│  │ 301 — Double Out       │ │  ← unselected variant card
│  │ Double Out · 1 Leg     │ │
│  └────────────────────────┘ │
│                             │
│  ┌────────────────────────┐ │
│  │ 301 — Master Out       │ │
│  │ Master Out · 1 Leg     │ │
│  └────────────────────────┘ │
│                             │
│  … more variants            │
│                             │
│  ─────────────────────────  │  ← separator before hint
│  Select a preset — you can  │
│  adjust the settings on the │
│  next screen                │  ← hint line (centred)
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Standard back arrow (returns to Home). Title is the game type name (e.g. "X01", "Cricket"). No overflow menu.
- **Variant card list:** Vertically scrollable list. Each card is full-width within `space4` (16dp) horizontal margin. Cards are separated by `space2` (8dp) vertical gap. No divider lines between cards — gap spacing is sufficient.
- **Hint line:** Below all variant cards, `space4` (16dp) top padding. Centred horizontally. Always visible (not scrolled away if list is short).

---

## Typography

| Element | Token | Color (unselected / selected) |
|---|---|---|
| AppBar title | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Variant name | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` / `colorOnPrimaryContainer` |
| Variant subtitle | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurfaceVariant` / `colorOnPrimaryContainer` |
| Hint line | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Unselected card background | `colorSurface` |
| Unselected card border | 1dp `colorOutline` |
| Selected card background | `colorPrimaryContainer` |
| Selected card border | 3dp left border `colorPrimary`; 1dp `colorOutline` on remaining 3 sides |
| Card corner radius | `radiusMedium` (12dp) |
| Hint line text | `colorOnSurfaceVariant` |

---

## Interactions

- **Variant card tap:** Minimum height 64dp; full-width tap target. Ripple `colorOnSurface` at 12% opacity. Navigates **directly** to Player Selection (`/game/player-selection`) with the chosen variant pre-populated in the game setup state. No confirm button.
- **Back button:** Returns to Home (`/`).
- **Card selection state:** The most recently tapped card shows selected styling (colorPrimaryContainer background, 3dp left border). If navigating back and returning, the previously selected variant remains highlighted.
- **Disabled "Custom" card (if present):** 38% opacity on foreground text; `colorSurfaceVariant` background; no `onTap`; Tooltip "Custom configuration coming soon".

---

## Edge Cases

- **No loading state:** The variant list is static configuration data, not loaded from a database. Render is synchronous.
- **No empty state:** Every game type has at least one pre-defined variant.
- **Single variant:** If a game type has only one variant, it is pre-selected and the navigation may skip this screen entirely (implementation decision — acceptable to show it with one card and the hint line).

---

## Special Notes

- **Subtitle format rules:**
  - **X01:** `"{score} · {outStrategy} Out · {legsToWin == 1 ? '1 Leg' : 'Best of N'}"`
    - Examples: `"501 · Double Out · 1 Leg"`, `"301 · Double Out · Best of 3"`
  - **Cricket:** Describes the variant rule. Examples: `"Close 15–20 & Bull · Standard"`, `"Cut-Throat · Score on opponent"`
  - **Practice:** No subtitle — game name is self-describing.
- **Hint line** is always rendered below the last card, separated by `space4` (16dp) top padding. It is not conditionally hidden.
- Page horizontal margin: `space4` (16dp). Vertical gap between cards: `space2` (8dp).
- AppBar title should reflect the game type as a human-readable label (e.g. "X01" not "x01", "Around the Clock" not "aroundTheClock").
