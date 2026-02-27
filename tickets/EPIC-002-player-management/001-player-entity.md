# TICKET-001: Player Entity

**Status:** Done
**Epic:** EPIC-002 — Player Management

---

## Description

Define the `Player` domain entity as a `freezed` immutable class. This is the data contract shared across the domain, data, and presentation layers.

---

## Acceptance Criteria

- [x] `Player` is a `@freezed` class in `lib/features/players/domain/entities/`
- [x] Fields: `playerId` (String UUID), `name` (String), `createdAt` (DateTime), `lastActive` (DateTime)
- [x] `@JsonKey` annotations map Dart field names to snake_case column names (`player_id`, `created_at`, `last_active`)
- [x] `Player.fromJson` factory is generated via `@freezed` + `json_serializable`
- [x] Generated files (`player.freezed.dart`, `player.g.dart`) are committed

---

## Files

- `lib/features/players/domain/entities/player.dart` — created
- `lib/features/players/domain/entities/player.freezed.dart` — generated
- `lib/features/players/domain/entities/player.g.dart` — generated

---

## Implementation Notes

- No `isActive` field on the entity — active/inactive is a persistence concern only. The repository filters inactive rows before returning results.
- `lastActive` is updated by the repository layer (via `touchPlayer`) whenever a player is involved in a game. It drives the default sort order in `getAllPlayers`.
- Domain entities must not import any Flutter or persistence packages — this file only depends on `freezed_annotation`.
