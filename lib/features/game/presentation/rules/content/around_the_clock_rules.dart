import '../game_rules.dart';

const aroundTheClockRules = GameRules(
  title: 'Around the Clock',
  tagline: 'Walk the board from 1 to 20. Hit each number in order.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Hit every number from 1 through 20 in sequence. The first player to land on 20 — having visited every number along the way — wins.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'You start on target number 1. Hit it with any dart to advance to 2, then 3, and so on up to 20.',
        'You throw three darts per turn. Each dart that lands on your current target moves you forward; darts on any other segment do nothing.',
        'Singles, doubles and triples all count as one hit in the standard variant — the multiplier gives no extra advantage.',
        'The bullseye is not part of the sequence; it is ignored.',
        'If you reach your final number mid-turn, any remaining darts are not thrown — the leg ends immediately.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The first player to complete the sequence wins the leg. With one player it is a solo drill against the dart count; with several players it is a race.',
    ),
    RulesSection(
      heading: 'Variants',
      bullets: [
        'Standard: hit 1 through 20 in ascending order; any multiplier counts.',
        'Reverse: start on 20 and count down to 1; any multiplier counts.',
        'Doubles only: ascending sequence from 1 to 20, but only doubles count — singles and triples on the right number do not advance you.',
      ],
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'Treat each turn as a small drill on one number. Once you advance, reset your aim for the next target.',
        'In doubles only the wire is narrow. Throwing smoothly matters more than throwing hard.',
      ],
    ),
  ],
);
