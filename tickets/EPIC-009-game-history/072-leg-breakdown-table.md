# TICKET-072: LegBreakdownTableWidget

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-068 (entities)

---

## Goal

Implement the expandable leg-by-leg breakdown table for the game detail page.

---

## Files to Create

- `lib/features/history/presentation/widgets/leg_breakdown_table_widget.dart`

---

## Acceptance Criteria

### `LegBreakdownTableWidget` (`StatefulWidget`)

Constructor: `{required List<GameEvent> events, required List<DartThrow> darts, required List<Competitor> competitors}`

**Leg reconstruction:**
1. Sort events by `localSequence`
2. For each `LegCompleted` event, collect all `DartThrown` events between the previous
   `LegCompleted` and the current one (by `localSequence` range)
3. Extract `turn_number` from each `DartThrown` event payload
4. Map those turn numbers to `DartThrow` records from the `darts` list

Private `_LegSummary` model: `legNumber`, `winnerName`, `dartsThrown`, `legDarts`.

**Table layout:** `Table` widget with 4 columns:
- Leg # (fixed 48px)
- Winner (flex)
- Darts (fixed 60px)
- Expand icon (fixed 40px)

For each leg, an additional `TableRow` is added immediately below when expanded,
containing the turn-by-turn darts in the Winner column (other cells empty).

**Expanded view:** darts grouped by `turnNumber`, formatted as space-joined segments
per turn. `_expandedLegs: Set<int>` tracks which leg numbers are open.

**Empty state:** `const Text('No legs completed')` centered in a `Padding`.
