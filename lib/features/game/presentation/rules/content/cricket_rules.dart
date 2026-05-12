import '../game_rules.dart';

const cricketStandardRules = GameRules(
  title: 'Cricket — Standard',
  tagline: 'Close the numbers 15 to 20 and the bull, then outscore the table.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Close all the cricket targets before your opponents, and finish ahead on points. '
          'You need both: closing alone is not enough if someone else has scored more on you.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'The targets are 15, 16, 17, 18, 19, 20 and the bullseye. Other numbers have no effect.',
        'You throw three darts per turn. A single counts as one hit on a target, a double as two hits, and a triple as three.',
        'The outer bull counts as one hit, the inner bull as two. Each bull hit is worth 25 points if you score on it.',
        'Hit a target three times to close it. Once closed, any extra hits on that target score points for you — but only while at least one opponent still has it open.',
        'Once every player has closed a number, it is dead and nobody can score on it.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'You win the leg the moment all of your targets are closed and your score is at least as high as every opponent\'s. '
          'If you close everything but trail on points, the leg continues — you need to score, or hope an opponent closes a number you are leading on.',
    ),
  ],
  relatedVariants: [
    RulesVariant(
      name: 'No Score',
      summary: 'Closing only. No points are tracked; the first player to close every target wins.',
    ),
    RulesVariant(
      name: 'Cut Throat',
      summary: 'Points hit on a number only you have closed are given to opponents. Lowest score wins.',
    ),
  ],
);

const cricketNoScoreRules = GameRules(
  title: 'Cricket — No Score',
  tagline: 'Closing only. Whoever shuts every number first wins.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Close every cricket target before your opponents. Points do not exist in this variant — the race is purely about shutting numbers down.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'The targets are 15, 16, 17, 18, 19, 20 and the bullseye.',
        'You throw three darts per turn. A single counts as one hit, a double as two, and a triple as three.',
        'The outer bull counts as one hit and the inner bull as two.',
        'Hit a target three times to close it. Extra hits beyond three have no effect — no points are scored in this variant.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'The first player to close all seven targets wins the leg. Strategy is pure efficiency: spend every dart on a number you have not closed yet.',
    ),
  ],
  relatedVariants: [
    RulesVariant(
      name: 'Standard',
      summary: 'Closed numbers score points for the player who closed them. Highest score with everything closed wins.',
    ),
    RulesVariant(
      name: 'Cut Throat',
      summary: 'Points from closed numbers go to opponents instead. Lowest score wins.',
    ),
  ],
);

const cricketCutThroatRules = GameRules(
  title: 'Cricket — Cut Throat',
  tagline: 'Same closing rules, reversed scoring. Points are punishment.',
  sections: [
    RulesSection(
      heading: 'Objective',
      body:
          'Close every cricket target — and finish on the lowest score at the table. '
          'Points are a punishment here: when you score on a number only you have closed, those points go to your opponents.',
    ),
    RulesSection(
      heading: 'How to play',
      bullets: [
        'The targets are 15, 16, 17, 18, 19, 20 and the bullseye.',
        'You throw three darts per turn. A single counts as one hit, a double as two, and a triple as three. The outer bull is one hit, the inner bull is two.',
        'Hit a target three times to close it.',
        'Once you close a number, extra hits on it add points to every opponent who has not closed it yet. You gain nothing on those darts.',
        'Once every player has closed a number, it is dead for everyone.',
      ],
    ),
    RulesSection(
      heading: 'Winning',
      body:
          'You win the leg when all of your targets are closed and your score is at least as low as every opponent\'s. '
          'If two or more players finish tied on the lowest score, whoever closed all the targets first wins. '
          'Closing every target with zero points is an instant win.',
    ),
    RulesSection(
      heading: 'Tips',
      bullets: [
        'Hitting a closed number a fourth time is usually bad: it feeds your opponents free points. Move to a number you still need to close.',
        'When several opponents share an open number, every overflow dart you throw on a closed number gives points to all of them.',
      ],
    ),
  ],
  relatedVariants: [
    RulesVariant(
      name: 'Standard',
      summary: 'Closed numbers score points for the player who closed them. Highest score with everything closed wins.',
    ),
    RulesVariant(
      name: 'No Score',
      summary: 'No points are tracked. The first to close every target wins.',
    ),
  ],
);
