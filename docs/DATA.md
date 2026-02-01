# Darts Game Data Structure

This document defines the data structure for storing player information, game configurations, and dart throws for statistical analysis.

## Player Information

### Player Data Fields
- `player_id`: UUID (string, universally unique identifier)
- `name`: Player's name (string)
- `created_at`: ISO 8601 timestamp
- `last_active`: ISO 8601 timestamp

## Game Data Structure

### Game Data Fields
- `game_id`: UUID (string, universally unique identifier)
- `game_type`: Type of game (string: "x01", "cricket", "around-the-clock", "killer", etc.)
- `game_configuration`: Game-specific configuration (object)
- `players`: Array of player IDs or team IDs who participated
- `teams`: Array of team objects (if team game)
- `start_time`: ISO 8601 timestamp
- `end_time`: ISO 8601 timestamp (nullable)
- `darts_sequence`: Array of all darts thrown in order
- `winner`: Player ID, team ID, or null if game interrupted
- `game_state`: Current game state for resuming interrupted games
- `is_completed`: Boolean indicating if game was completed

### Dart Throw Data Fields (within darts_sequence)
- `player_id`: Player who threw the dart (string)
- `turn_number`: Turn number in the game (integer)
- `dart_number`: Dart number in turn (1, 2, or 3)
- `score`: Points scored (integer)
- `segment`: Segment hit (string: "20", "T20", "D16", "SB", "DB", etc.)
- `x`: X-coordinate of dart impact (float, optional)
- `y`: Y-coordinate of dart impact (float, optional)

## Game Type Configurations

### X01 Configuration
- `starting_score`: 301, 501, 701, or 901
- `number_of_rounds`: 15, 30, 50, or 80
- `in_strategy`: "straight", "double", or "master"
- `out_strategy`: "straight", "double", or "master"
- `player_handicaps`: Object mapping player IDs to handicap values (e.g., {"player1": -50, "player2": 0})

### Cricket Configuration
- `variant`: "standard", "cut-throat", or "no-score"
- `numbers_in_play`: Array of numbers (15-20) and "bull"

### Around the Clock Configuration
- `direction`: "ascending", "descending", or "random"
- `target_numbers`: Array of numbers 1-20
- `required_hits`: 1, 2, or 3

### Killer Configuration
- `starting_lives`: Number of lives (typically 3)
- `number_assignment`: "random", "manual", or "sequential"
- `hit_requirement`: "single", "double", or "triple"

## Implementation Considerations

- **Data Storage**: SQLite database (as specified in README)
- **Data Validation**: Schema validation for all stored data
- **Backup Strategy**: Regular backups of game data
- **Export/Import**: Allow users to export their game history
- **Privacy Compliance**: No anonymization or encryption required
- **Data Retention**: No automatic cleanup - retain all game history indefinitely
- **Performance**: No indexing or partitioning required for expected dataset sizes

## Team Game Support

### Team Object Structure
- `team_id`: UUID (string)
- `team_name`: Team name (string)
- `players`: Array of player IDs in the team
- `team_order`: Order of players in team rotation

## Game State for Resuming

### Game State Data
- `current_player`: Player ID of current player
- `current_turn`: Current turn number
- `current_scores`: Object mapping player/team IDs to current scores
- `closed_numbers`: Object mapping player/team IDs to closed numbers (for cricket)
- `remaining_lives`: Object mapping player/team IDs to remaining lives (for killer)
- `game_specific_state`: Additional game-specific state data

## Key Requirements Met

✅ **Player information storage**: Name and metadata with UUIDs
✅ **Game configuration storage**: Detailed settings for each game type
✅ **Dart sequence storage**: Every dart thrown stored in order for statistics
✅ **No pre-computed stats**: All statistics will be computed from raw data
✅ **Optional coordinates**: Support for game replay features
✅ **Team game support**: Track team games separately from individual games
✅ **Game state persistence**: Support for resuming interrupted games
✅ **Unlimited data retention**: No automatic cleanup of game history
✅ **UUID identification**: Using UUIDs for both players and games
