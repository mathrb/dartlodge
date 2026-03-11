# SCR-016 — Player Statistics Page

**Route:** `/stats/player/:playerId`
**File:** `lib/features/statistics/presentation/pages/player_stats_page.dart`

---

## Design Principles

- **P1 — Key stats readable at a glance:** Summary cards use the large Oswald type token; the most important values are immediately visible without scrolling.
- **P3 — All metrics on screen:** The scrollable layout allows the player to access all stat categories without navigating away.
- **P4 — Data-dense but organized:** The broadcast scoreboard aesthetic — clean rows, restrained color — keeps dense metric tables legible.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "ALICE — Stats" ←  │
├─────────────────────────────┤
│  [X01] [Cricket] [Prac] [+]│  ← game-type tab bar
├─────────────────────────────┤
│  (X01 tab content below:)   │
│                             │
│  ┌──────┐┌──────┐┌──────┐  │
│  │  142 ││  89  ││  12  │  │  ← 3 summary cards, equal width
│  │ Legs ││ Legs ││ Solo │  │
│  │Played││  Won ││Games │  │
│  └──────┘└──────┘└──────┘  │
│                             │
│  [All X01▾][501][301][…]   │  ← variant chip row (horizontal scroll)
│                             │
│  [Last 10] [Last 100] [All] │  ← time range segmented control
│                             │
│  ┌─────────────────────────┐│
│  │   PPR trend line chart  ││  ← min 160dp height
│  │   [📊 Checkout %]       ││  ← toggle chip inside/below chart
│  └─────────────────────────┘│
│                             │
│  ─ Metric ──────── Value ─  │
│  PPR                  54.3  │
│  First 9 PPR          64.1  │
│  Checkout %            32%  │
│  Highest checkout       121  │
│  Win %                 62%  │
│  60+  (total / leg) 145/4.2 │
│  100+ (total / leg)  43/1.2 │
│  140+ (total / leg)   8/0.2 │
│  180  (total / leg)  2/0.06 │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Player Detail page. Title: `"{NAME} — Stats"` where NAME is the player name in ALL CAPS (e.g. "ALICE — Stats").
- **Tab bar:** Four tabs — X01, Cricket, Practice, Others. Tab indicator is a 2dp underline in `colorPrimary`. Only X01 shows full content; the other three tabs show a "coming soon" placeholder.
- **Summary cards row (X01):** Three equal-width stat cards. Legs Played | Legs Won | Solo Games. "Solo Games" = count of distinct completed game sessions (not legs).
- **Variant chip selector:** Horizontally scrollable chip row. First chip "All X01" is selected by default. Additional chips for each distinct starting score present in the player's data (e.g. "501", "301"). Selecting a chip filters both the chart and the metric table below.
- **Time range segmented control:** Three segments: "Last 10", "Last 100", "All" (default: All). Applies to both the chart and the metric table.
- **Trend chart:** Full-width, minimum 160dp height. Line chart showing PPR over time (game/leg index). Optional second line for Checkout % (toggled by chip).
- **Metric table:** Two-column table (Metric | Value). Scrollable as part of the page scroll.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Tab label (active) | `textLabelLarge` (DM Sans Medium 14sp) | `colorPrimary` |
| Tab label (inactive) | `textLabelLarge` | `colorOnSurfaceVariant` |
| Tab underline indicator | — | `colorPrimary` (2dp) |
| Summary card value | `textScoreSmall` (Oswald Bold 36sp) | `colorPrimary` |
| Summary card label | `textLabelMedium` (DM Sans Medium 12sp) | `colorOnSurfaceVariant` |
| Variant chip label (selected) | `textLabelMedium` | `colorOnPrimaryContainer` |
| Variant chip label (unselected) | `textLabelMedium` | `colorOnSurfaceVariant` |
| Time range segment label (selected) | `textLabelLarge` | `colorOnPrimary` |
| Time range segment label (unselected) | `textLabelLarge` | `colorOnBackground` |
| Chart empty-state message | `textBodyMedium` | `colorOnSurfaceVariant` |
| Metric table — metric name | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnBackground` |
| Metric table — metric value | `textBodyMedium` | `colorPrimary` |
| "Coming soon" placeholder text | `textBodyMedium` | `colorOnSurfaceVariant` at 60% opacity |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Tab bar background | `colorBackground` |
| Tab indicator underline | `colorPrimary` (2dp) |
| Summary card background | `colorSurface` |
| Summary card corner radius | `radiusMedium` (12dp) |
| Summary card elevation | 1 |
| Variant chip (selected) background | `colorPrimaryContainer` |
| Variant chip (unselected) background | `colorSurfaceVariant` |
| Variant chip corner radius | `radiusXSmall` (4dp) |
| Time range segment (selected) fill | `colorPrimary` |
| Time range segment (unselected) background | `colorSurface` |
| Trend chart background | `colorSurface` |
| Trend chart corner radius | `radiusMedium` (12dp) |
| Trend chart line (PPR) | `colorPrimary` |
| Trend chart area fill (PPR) | `colorPrimaryContainer` at 30% opacity |
| Trend chart line (Checkout %) | `colorSecondary` |
| Metric table even rows | `colorSurface` |
| Metric table odd rows | `colorBackground` |

---

## Tab Content

### X01 Tab (full content — spec above)

### Cricket Tab
- Shows: "Stats for Cricket coming soon."
- Centered in available space.
- Icon: cricket bat or generic stats icon, 64dp, `colorOnSurfaceVariant` at 60% opacity.
- Text: `textBodyMedium colorOnSurfaceVariant` at 60% opacity.
- No variant selector, no chart, no metric table.

### Practice Tab
- Shows: "Stats for Practice coming soon."
- Same styling as Cricket tab placeholder.

### Others Tab
- Shows: "Stats for other game types coming soon."
- Same styling as Cricket tab placeholder.

---

## Variant Chip Selector (X01 only)

- Horizontally scrollable `Row` of chips.
- First chip: "All X01" — always present; selected by default.
- Subsequent chips: one per distinct starting score found in the player's completed X01 games (e.g. if the player has played 501 and 301, show chips "501" and "301").
- If the player has only played one starting score: show "All X01" and that one starting score chip.
- Chip minimum height: 32dp. Minimum tap target: 48dp height (achieved via padding).
- Selecting a chip re-filters the chart and metric table below. The time range selection is preserved across chip changes.
- Only one chip selected at a time.

---

## Time Range Segmented Control (X01 only)

- Three segments in a single segmented control widget: "Last 10" | "Last 100" | "All".
- Default selection: "All".
- "Last 10": use the 10 most recent legs completed (for the selected variant filter).
- "Last 100": use the 100 most recent legs.
- "All": no limit.
- Changing segment re-filters both the chart and the metric table.
- Selected segment fill: `colorPrimary`; text: `colorOnPrimary`.
- Unselected segment: `colorSurface` bg; text: `colorOnBackground`.
- Segmented control border: 1dp `colorOutline`, `radiusSmall` outer corners.

---

## Trend Chart (X01 only)

- Full-width within `space4` (16dp) horizontal margin.
- Minimum height: 160dp.
- X axis: leg index (oldest at left, newest at right). No axis labels unless implementation has space.
- Y axis: PPR value. Auto-scales to the data range.
- Primary line: PPR per leg, `colorPrimary`, 2dp width.
- Area fill below primary line: `colorPrimaryContainer` at 30% opacity.
- Optional secondary line: Checkout % per leg, `colorSecondary`, 2dp width (toggle via chip).
- Tap on data point: shows a small tooltip with PPR value and the date of that game.
- Chart renders inside a `colorSurface` container with `radiusMedium` corner radius.

**Checkout % toggle chip:**
- Label: "📊 Checkout %" (or "CO%" if emoji not used).
- Positioned immediately below or inside the chart container.
- Selected state: `colorPrimaryContainer` bg, `colorOnPrimaryContainer` text.
- Unselected: `colorSurfaceVariant` bg, `colorOnSurfaceVariant` text.
- Minimum height: 32dp.

**Empty state (< 2 data points):**
- Centered inside the chart container: "Not enough data yet" in `textBodyMedium colorOnSurfaceVariant`.
- Chart line and area fill are not rendered.

---

## Metric Table (X01 only)

The table rows, in order:

| Row | Metric | Value format |
|---|---|---|
| 1 | PPR | Decimal to 1 place — e.g. "54.3" |
| 2 | First 9 PPR | Decimal to 1 place |
| 3 | Checkout % | Integer percentage — e.g. "32%" |
| 4 | Highest checkout | Integer — e.g. "121" |
| 5 | Win % | Integer percentage — e.g. "62%" |
| 6 | 60+ (total / leg) | Two values — e.g. "145 / 4.2" |
| 7 | 100+ (total / leg) | Two values — e.g. "43 / 1.2" |
| 8 | 140+ (total / leg) | Two values — e.g. "8 / 0.2" |
| 9 | 180 (total / leg) | Two values — e.g. "2 / 0.06" |

- Total column: integer count.
- Per-leg column: decimal to 2 places (e.g. "0.06" for rare events).
- Row height: 48dp minimum.
- Even rows (1, 3, 5, 7, 9): `colorSurface` background.
- Odd rows (2, 4, 6, 8): `colorBackground` background.
- No divider lines between rows (row color alternation is sufficient separation).
- Metric name: left-aligned, `textBodyMedium colorOnBackground`.
- Value: right-aligned, `textBodyMedium colorPrimary`.

---

## Edge Cases

**No data for selected filter (e.g. no 301 games):**
- Summary cards show "—".
- Variant chip for that starting score is still shown (it exists because the player has played it, even if zero legs match the time filter).
- Chart shows empty state message.
- Metric table shows "—" for all rows.

**Single data point:**
- Chart shows empty state ("Not enough data yet").
- Metric table shows available values for the one data point.

**Tab switch:**
- Reset variant selector to "All X01" and time range to "All" when switching back to X01 tab, OR preserve the selection — implementation decision. Document the choice clearly in the provider.

**Player with no completed games:**
- All summary cards show "—".
- No variant chips (other than "All X01").
- Chart shows empty state.
- Metric table shows "—" for all rows.

---

## Special Notes

- **Route:** `/stats/player/:playerId` — not `/stats/career/:playerId`. The router must use this exact path.
- **Projection data for trend chart:** The flat `PlayerStats` entity is insufficient for the trend chart; a per-game (or per-leg) snapshots list is needed to draw a time-series line. Flag this as a data requirements concern for the provider implementation — the provider may need to call a different repository method that returns a list of `{date, ppr, checkoutPct}` per leg.
- **No leaderboard on this page.** This is strictly a per-player stats view.
- **PPR definition:** Points Per Round (3-dart turn). Also called "3-dart average".
- **First 9 PPR:** The average score across the first 9 darts (3 turns) of each leg. Measures opening-leg consistency.
- Page horizontal margin: `space4` (16dp).
- Bottom safe area: `space16` (64dp).
