import '../game_rules.dart';

const checkoutPracticeRules = GameRules(
  title: '170 Checkout',
  tagline: 'The biggest checkout in darts. Take it down on a double.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Start on 170 and reduce your score to exactly zero on a double. '
          'This is a solo drill for grooving the classic 170 finish — typically triple 20, triple 20, double bull.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'You begin with a score of 170 and are always "in" — every dart counts from the first throw.',
        'Standard double-out finishing applies: the dart that takes you to zero must be a double, and the inner bull counts as a double.',
        'You throw three darts per turn. A single scores its face value, a double scores twice, and a triple scores three times.',
        'If a dart would take your score below zero, leave you on exactly one, or land you on zero without a double, that is a bust. Your score reverts to where it stood at the start of the turn and the rest of the turn is forfeited.',
        'The drill continues across as many turns as it takes — there is no turn limit.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The drill ends as soon as you check out, or when you tap End Drill. The checkout score shown on the summary screen is the score you were on at the start of your finishing turn — useful for tracking how often you finish from 170 in one visit versus needing to set up first.',
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'The textbook route is triple 20, triple 20, double bull. The other classic is triple 20, triple 18, double 18.',
        'If your first dart goes wide, recalculate fast — many 170-starts only have a single one-visit path left after a stray.',
      ],
    ),
  ],
);
