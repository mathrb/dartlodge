# Blind Cricket

## Overview
A variation of the Cricket game where players do not know which numbers are in play. The goal is to close all numbers and have the highest score.

## Rules
- **Numbers in Play**: Unknown to players
- **Objective**: Close all numbers and have the highest score
- **Closing a Number**: Hit a number three times (any combination of singles, doubles, or triples)
- **Scoring**: Once a number is closed by a player, they can score points on that number until the opponent closes it
- **Winning**: The first player to close all numbers and have the highest score wins

## Scoring
- **Single**: Counts as one hit
- **Double**: Counts as two hits
- **Triple**: Counts as three hits
- **Bullseye**: 25 points (outer bull) or 50 points (inner bull)

## Variations
- **Team Blind Cricket**: Players form teams, and the goal is to close all numbers and have the highest score

## Implementation Notes
- Randomly select target numbers at game start
- Hide target numbers from players
- Track hits per number for each player
- Scoring logic changes after a number is closed