# Cricket

## Overview
A strategic game where players aim to "close" specific numbers (15 through 20 and the bullseye) by hitting each number three times. In standard cricket, the player who closes all numbers and has the highest score wins. In cut-throat cricket, the rules are reversed - lowest score wins!

## Rules
- **Numbers in Play**: 15, 16, 17, 18, 19, 20, and bullseye
- **Objective**: 
  - **Standard Cricket**: Close all numbers and have the highest score
  - **Cut-Throat Cricket**: Close all numbers and have the lowest score
- **Closing a Number**: Hit a number three times (any combination of singles, doubles, or triples)
- **Scoring**: 
  - **Standard Cricket**: Once a number is closed by a player, they can score points on that number until opponents close it
  - **Cut-Throat Cricket**: When a player hits a closed number, points are added to opponents who haven't closed that number. The player who hit it scores 0.
- **Winning**: 
  - **Standard Cricket**: First player to close all numbers AND have the highest score wins
  - **Cut-Throat Cricket**: First player to close all numbers AND have the lowest score wins

## Scoring
- **Single**: Counts as one hit
- **Double**: Counts as two hits
- **Triple**: Counts as three hits
- **Bullseye**: 25 points (outer bull) or 50 points (inner bull)

## Variations
- **Cut-Throat Cricket**: 
  - **The Great Reversal**: LOWEST score wins (opposite of standard cricket)
  - When you score on a closed number, points go to opponents who haven't closed it
  - You gain 0 points when hitting closed numbers
  - Must close ALL numbers to win (same as standard cricket)
  - Winning condition: Close all numbers AND have the lowest score
  - Special cases:
    - If everyone closes everything: Lowest score wins
    - If a player closes everything with 0 points: Immediate victory!
    - Tie for lowest score: Whoever closed first wins
- **No Score Cricket**: Only closing numbers matters; no additional scoring

## Implementation Notes
- Need to track hits per number for each player
- Scoring logic differs significantly between standard and cut-throat variants:
  - Standard: Points go to the player who closed the number
  - Cut-Throat: Points go to opponents who haven't closed the number, player gets 0
- Game ends when:
  - Standard: One player closes all numbers AND has highest score
  - Cut-Throat: One player closes all numbers AND has lowest score