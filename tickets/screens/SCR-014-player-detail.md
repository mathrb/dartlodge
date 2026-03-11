# SCR-014 — Player Detail Page

**Route:** `/players/:playerId`
**File:** `lib/features/players/presentation/pages/player_detail_page.dart`

---

## Design Principles

- **P4 — Clean form, inline editing:** No modal edit workflows. The player's name is directly editable by tapping. No separate edit icon in the AppBar.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "ALICE"        [🗑]│  ← delete icon tinted in colorError
├─────────────────────────────┤
│                             │
│          [  ○  ]            │  ← 80dp circular avatar (centered)
│                             │
│       [   ALICE   ]         │  ← inline editable text field (textDisplayLarge)
│                             │
├─── stat cards ──────────────┤
│  ┌──────────┐ ┌──────────┐  │
│  │    42    │ │   62%    │  │  ← 2-column stat cards (equal width)
│  │  Games   │ │ Win Rate │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────────────────────┐│
│  │        1 204             ││  ← full-width stat card
│  │      Darts Thrown        ││
│  └──────────────────────────┘│
├─── action buttons ──────────┤
│  [ VIEW STATISTICS        ] │
│  [ VIEW GAME HISTORY      ] │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Player List. Title shows player name in `textHeadingMedium`. Trailing delete icon [🗑] with 48×48dp tap target.
- **Avatar:** 80dp diameter, centered horizontally. Auto-updates initials as the name is edited.
- **Inline name field:** Below avatar, centered. Renders as editable text when tapped. Behaves like an inline text field (no visible border in resting state — appears as plain large text). When focused: shows a bottom underline or subtle focus indicator. Return key or tap-away saves.
- **Stat cards:** Two equal-width cards in a row (Games Played, Win Rate), then one full-width card (Darts Thrown). Cards have `radiusMedium` corners and elevation 1.
- **Action buttons:** Two full-width buttons below the stat cards. "VIEW STATISTICS" is filled; "VIEW GAME HISTORY" is outlined.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title (player name) | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Delete icon | — | `colorError` |
| Inline name field (resting/editing) | `textDisplayLarge` (DM Sans SemiBold 32sp) | `colorOnBackground` |
| Avatar initials | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnSecondaryContainer` |
| Stat card value | `textScoreSmall` (Oswald Bold 36sp) | `colorPrimary` |
| Stat card label | `textLabelMedium` (DM Sans Medium 12sp) | `colorOnSurfaceVariant` |
| "VIEW STATISTICS" button | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| "VIEW GAME HISTORY" button | `textLabelLarge` | `colorPrimary` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Avatar background | `colorSecondaryContainer` |
| Avatar border | none |
| Inline name field focus indicator | bottom 2dp underline in `colorPrimary`; no outline |
| Stat card background | `colorSurface` |
| Stat card border | none (elevation 1 provides depth) |
| Stat card corner radius | `radiusMedium` (12dp) |
| "VIEW STATISTICS" background | `colorPrimary` filled |
| "VIEW GAME HISTORY" border | `colorPrimary`, outlined style |
| "VIEW GAME HISTORY" text | `colorPrimary` |
| Delete icon color | `colorError` |

---

## Interactions

**Inline name field:**
- Resting state: renders as `textDisplayLarge` centered text, no visible border or field outline.
- Tap to activate: text cursor appears; bottom underline 2dp `colorPrimary` appears as focus indicator.
- Return key / tap outside (unfocus): saves the new name. Calls `updatePlayerName` notifier method.
- AppBar title updates live as the user types (mirrors the field value).
- Avatar initials update live as the user types.
- Validation runs on save (not on every keystroke):
  - Non-empty name required: if field is blank on save, restore previous name and show snackbar "Name cannot be empty".
  - Unique name required: if the name matches another player, show snackbar "A player named {name} already exists" in `colorErrorContainer` bg.
  - Max 24 characters enforced: field does not accept input beyond 24 chars.

**Delete icon [🗑] (48×48dp tap target):**
- Shows confirmation dialog:
  - Title: "Delete {name}?" — `textHeadingSmall`
  - Body: "This cannot be undone. All games featuring this player will be preserved, but this player cannot be added to new games." — `textBodyMedium`
  - Cancel: TextButton `colorOnBackground`
  - Confirm "DELETE": FilledButton `colorError` background, `colorOnError` text
  - Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- On confirm: calls `deletePlayer` → navigates back to Player List.
- If deletion fails (player has active games), show error snackbar: `colorErrorContainer` bg.

**"VIEW STATISTICS":** Navigates to `/stats/player/:playerId`.

**"VIEW GAME HISTORY":** Navigates to `/history` with a player filter pre-applied for this player.

---

## Edge Cases

**No stats (new player, no games played):**
- Stat card values show "—" (em dash) in place of numbers.
- `textScoreSmall` size is maintained even for "—".

**Very long player name (max 24 chars):**
- AppBar title may need to truncate if the font renders wider than the AppBar allows. Use `overflow: TextOverflow.ellipsis` on the AppBar title.
- The inline name field (centered, full display) should accommodate 24 chars at 32sp without truncation — container is full-width.

**Loading:**
- Centered `CircularProgressIndicator` in `colorPrimary`.
- Shown while player data and stats are fetched.

**Error:**
- Centered `error_outline` icon 48dp.
- "Failed to load player." `textBodyLarge colorOnBackground`.
- "Retry" TextButton `colorPrimary`.

---

## Special Notes

- **No edit icon in AppBar.** Editing is inline only. Do not add a pencil icon or any edit affordance in the AppBar.
- **Stat cards show game-type-agnostic metrics only:**
  - Games Played: total completed games across all game types.
  - Win Rate: wins / completed games with a defined winner (percentage, no decimal, e.g. "62%").
  - Darts Thrown: total darts thrown across all games. Formatted with space as thousands separator (e.g. "1 204" not "1204").
- **X01-specific stats** (3-dart avg, Checkout %) are **not shown here**. Those appear on the Statistics page (`/stats/player/:playerId`).
- **Avatar diameter:** 80dp. Font for initials is at `textHeadingMedium` scale (20sp) for legibility at 80dp size.
- **Vertical spacing:** `space8` (32dp) between avatar and name field; `space6` (24dp) between name field and stat cards; `space4` (16dp) between stat card rows; `space6` (24dp) between stat cards and action buttons; `space3` (12dp) between the two action buttons.
- Page horizontal margin: `space4` (16dp).
