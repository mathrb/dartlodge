import '../game_rules.dart';

const bobs27Rules = GameRules(
  title: "Bob's 27",
  tagline: 'Twenty rounds of doubles. Miss them all and you are out.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          "Hit every double from D1 through D20 in order, one number per round. "
          "Your score starts at 27 and climbs each time you land a double of the round's number — and drops sharply every round you miss.",
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'You begin with a score of 27.',
        'There are 20 rounds. In round 1 the target is double 1, in round 2 it is double 2, and so on up to double 20 in round 20.',
        'Each round you throw three darts at the round\'s double.',
        'For every dart that lands on the target double, your score goes up by twice the round number. Three doubles of 20 in the final round add 120.',
        'If none of your three darts hits the target double, your score drops by twice the round number instead.',
        'Singles, triples and any other segment do nothing — only the round\'s exact double counts.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The drill is solo. It ends after round 20, or sooner if your score drops to zero or below. '
          'Your final score is your result. A perfect run — three doubles every round — totals 1437.',
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'A single missed round on a low number costs little. A wipe on the late rounds is catastrophic — D17, D18, D19 and D20 each cost more than 30 points.',
        'The drill rewards consistency, not heroics. Trust your stance and your release.',
      ],
    ),
  ],
);
