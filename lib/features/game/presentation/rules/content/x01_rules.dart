import '../game_rules.dart';

const x01Rules = GameRules(
  title: 'X01',
  tagline: 'Race to zero. Last dart has to land just right.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Every player starts on the same score and tries to reduce it to exactly zero. '
          'The first player to do so under the chosen finishing rule wins the leg.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'You throw three darts per turn. The total of those darts is subtracted from your remaining score.',
        'A single scores its face value, a double scores twice, and a triple scores three times. The outer bull scores 25, the inner bull 50.',
        'If a dart would take your score below zero, leave you on exactly one, or finish the leg without satisfying the chosen out rule, you bust. Your score reverts to where it was at the start of the turn and the rest of the turn is forfeited.',
        'Players alternate turns until someone closes out the leg.',
      ],
    ),
    RulesSection(
      heading: 'In and out strategies',
      body:
          'Each match is configured with an in strategy (when your darts start counting) and an out strategy (how you are allowed to finish).',
      bullets: [
        'Straight in: every dart counts from the very first throw.',
        'Double in: you have to land a double before any dart starts scoring in the leg.',
        'Master in: a double or a triple opens scoring in the leg.',
        'Straight out: finish on any segment that takes you to zero.',
        'Double out: the dart that takes you to zero must be a double (the inner bull counts as a double). This is the championship standard.',
        'Master out: the finishing dart must be a double or a triple.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'You win a leg by reducing your score to exactly zero on a dart that satisfies the out rule. '
          'A match runs over a configurable number of legs; the first player to reach the target number of legs wins the match.',
    ),
    RulesSection(
      heading: 'Variants',
      bullets: [
        '301: short, sharp games. Strong finishing matters from the very first turn.',
        '501: the championship classic. Long enough for high scoring to swing the leg.',
        '701 and 901: longer games that reward consistent scoring over multiple visits.',
      ],
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'Anything from 170 down is a possible checkout, but only certain numbers are finishable in two or three darts with double out.',
        'If you cannot finish this visit, set yourself up. Leaving 32 (double 16) or 40 (double 20) is a friendlier setup than awkward odd numbers.',
        'Avoid leaving yourself on one with double out. It is an automatic bust.',
      ],
    ),
  ],
);
