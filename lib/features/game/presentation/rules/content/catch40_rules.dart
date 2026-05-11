import '../game_rules.dart';

const catch40Rules = GameRules(
  title: 'Catch 40',
  tagline: 'Forty checkouts from 61 to 100. Score points by finishing fast.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Work through forty checkout targets, from 61 up to 100. For each target you get up to six darts to take the score down to exactly zero on a double. '
          'How quickly you finish decides how many points the target is worth.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'Each round you are given a fixed remaining score: 61 for the first target, 62 for the second, and so on up to 100 for the last.',
        'You have up to six darts per target, split across two visits of three.',
        'Standard double-out finishing applies. Going below zero, landing on one, or hitting zero with a non-double counts as a bust: the remaining score resets to the original target for that round, but the dart still counts towards your six.',
        'A checkout in one or two darts scores 3 points.',
        'A checkout in three darts scores 2 points — except the target of 99, which still scores 3.',
        'A checkout in four, five, or six darts scores 1 point.',
        'Failing to check out within six darts scores 0 points for that target.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The drill is solo. There is no opponent to beat — your score is the total points across all forty targets, with a maximum of 120. Treat it as a benchmark to improve over time.',
    ),
  ],
);
