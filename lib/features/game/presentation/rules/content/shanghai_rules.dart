import '../game_rules.dart';

const shanghaiRules = GameRules(
  title: 'Shanghai',
  tagline: 'A different number every round. Score what you can, or end it on a Shanghai.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Score as many points as possible across a fixed number of rounds. '
          'Each round targets a specific number, starting at 1 and counting up — only hits on that number score. '
          'Landing a single, double and triple of the target number in the same turn is a Shanghai, which wins the game outright.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'The game runs for a configurable number of rounds (seven by default). Round 1 targets the number 1, round 2 targets 2, and so on.',
        'You throw three darts per round.',
        'Only hits on the current round\'s number score. A single scores the face value, a double scores twice, and a triple scores three times.',
        'Hits on any other number — including the bull — score nothing.',
        'If you hit the round\'s single, double and triple within the same three darts, that is a Shanghai. The game ends immediately and the Shanghai counts as a win.',
        'Otherwise the round ends after three darts and play advances to the next number.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'Played solo, the drill ends when you finish the final round. There is no opponent to beat — your total score is your result. '
          'A Shanghai in any round ends the drill early as an instant win.',
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'The triple is where the big scores live. Three triples of 7 in the last round is 63 points in one turn.',
        'Hunting for the Shanghai is high-risk, high-reward — chasing two missing multipliers usually costs you a clean scoring turn.',
      ],
    ),
  ],
);
