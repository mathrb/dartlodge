import '../game_rules.dart';

const countUpRules = GameRules(
  title: 'Count-Up',
  tagline: 'Reverse X01. No checkout, no bust — just stack points for a fixed number of rounds.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Score as many points as possible over a fixed number of rounds. '
          'Every dart adds to your running total — there is no checkout to land and no bust to worry about. '
          'When the last round ends, whoever has the highest total wins.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'The game runs for a configurable number of full rounds: 8, 12, 16, or 20.',
        'You throw three darts per turn. The value of every dart is added to your score: a single scores its face value, a double scores twice, and a triple scores three times. The outer bull is 25 and the inner bull is 50.',
        'A miss simply scores nothing — your turn still uses up a dart.',
        'There is no in strategy and no out strategy. Every dart counts from the first throw, and the turn always lasts the full three darts.',
        'Players can be given a handicap at setup — a head start of 50, 100, 150, or 200 points added to their starting score.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The game ends when the last player of the final round finishes their turn. The highest total wins. '
          'If two or more players tie at the top, the game is recorded as a tie with no winner.',
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'Without a bust to dodge, the triple 20 is always the best target — aim hard, every visit.',
        'A leader cannot ice the game early; every round plays out in full. A late three-triple turn can flip the result.',
      ],
    ),
  ],
);
