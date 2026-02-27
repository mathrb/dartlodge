# TICKET-009: PlayerCardWidget & PlayerAvatarWidget

**Status:** Todo
**Epic:** EPIC-002 — Player Management

---

## Description

Build the two shared player UI components used across the player list, player selection (EPIC-004), and wherever a player is represented compactly.

---

## Acceptance Criteria

- [ ] `PlayerCardWidget` is a `StatelessWidget` at `lib/features/players/presentation/widgets/player_card_widget.dart`
- [ ] `PlayerCardWidget` accepts: `player` (Player), `onTap` (VoidCallback?), optional `trailing` (Widget?)
- [ ] Displays: `PlayerAvatarWidget` on the left, player name in body text, last-active date as subtitle
- [ ] Item height: 64pt; avatar 40×40pt; horizontal padding 16pt (per UI spec)
- [ ] Tappable via `InkWell` / `ListTile`; `onTap` is nullable — widget renders non-interactively if null
- [ ] `PlayerAvatarWidget` is a `StatelessWidget` at `lib/features/players/presentation/widgets/player_avatar_widget.dart`
- [ ] `PlayerAvatarWidget` accepts: `player` (Player), `size` (double, default 40)
- [ ] Renders a `CircleAvatar` with the player's initials (first letter of name, uppercase) as the fallback
- [ ] Avatar background colour is derived deterministically from `player.playerId` (e.g., hash mod colour palette) so the same player always gets the same colour

---

## Files

- `lib/features/players/presentation/widgets/player_card_widget.dart` — to create
- `lib/features/players/presentation/widgets/player_avatar_widget.dart` — to create

---

## Implementation Notes

- `PlayerCardWidget` uses `ListTile` internally for consistent Material padding and ripple behaviour. `leading` = `PlayerAvatarWidget`, `title` = name, `subtitle` = "Last active [date]", `trailing` = optional.
- `PlayerAvatarWidget` colour derivation: `player.playerId.hashCode % colours.length` where `colours` is a fixed `const` list of `Color` values. This is deterministic and requires no stored state.
- These widgets are pure — they accept `Player` entities and callbacks; they do not read any Riverpod providers. This keeps them testable as `StatelessWidget` with zero dependencies.
- `trailing` on `PlayerCardWidget` allows callers to inject a checkbox (EPIC-004 player selection) or an overflow menu (edit/delete) without modifying this widget.
- Last-active date subtitle format: "Active [relative]" or formatted date — decide consistently with the detail screen formatting (use `intl`).
