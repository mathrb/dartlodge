# EPIC-002: Player Management

## Goal
Players can be created, listed, and managed from a dedicated UI, serving as the entry point for all game setup flows.

## Status
[~] In progress — repository done; UI is a stub

## Scope — In
- Player list screen: all players sorted by last active date, empty-state prompt
- Create player flow: name input (validation: non-empty, unique, max 30 chars), optional avatar selection
- Edit player name (inline or via detail screen)
- Delete player (soft: only allowed if player has no game history; hard: blocked with `RepositoryException`)
- Player detail screen: basic info + career stats preview card (links to EPIC-008)
- Riverpod providers:
  - `allPlayersProvider` — `AsyncNotifierProvider` watching `watchAllPlayers()` stream
  - `playerProvider(id)` — single player by UUID
  - `createPlayerNotifier` — form state + submission
- `PlayerState` (freezed): list, loading, error states
- `PlayerFormState` (freezed): name field, validation errors, submitting flag

## Scope — Out
- Player account linking to backend (EPIC-010)
- Career statistics detail (EPIC-008)
- Player selection during game setup (EPIC-004)

## Key User Stories
- As a player, I can create a profile with my name so that my scores are tracked separately from others.
- As a player, I can see a list of all players so that I can choose who is playing today.
- As a player, I can edit my name so that I can correct mistakes.
- As a player, I cannot delete myself if I have game history so that historical data is preserved.

## Technical Components
- `lib/features/players/domain/entities/player.dart` — already exists
- `lib/features/players/domain/repositories/player_repository.dart` — already exists
- `lib/features/players/data/repositories/` — sqflite + drift implementations (done)
- `lib/features/players/presentation/pages/player_list_page.dart`
- `lib/features/players/presentation/pages/create_player_page.dart`
- `lib/features/players/presentation/pages/player_detail_page.dart`
- `lib/features/players/presentation/widgets/player_card_widget.dart`
- `lib/features/players/presentation/widgets/player_avatar_widget.dart`
- `lib/features/players/presentation/providers/players_provider.dart`
- `lib/features/players/presentation/state/player_state.dart`
- `lib/features/players/presentation/state/player_form_state.dart`

## Dependencies
- EPIC-001 (database + repository implementations must be complete)

## Spec References
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — player list screen layout, player selection component
- `docs/STATE_MANAGEMENT.md` — Riverpod provider patterns
- `docs/REPOSITORY_INTERFACES.md` — `PlayerRepository` method signatures
