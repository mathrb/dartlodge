class GameRules {
  final String title;
  final String tagline;
  final List<RulesSection> sections;
  final List<RulesVariant> relatedVariants;

  const GameRules({
    required this.title,
    required this.tagline,
    required this.sections,
    this.relatedVariants = const [],
  });
}

class RulesSection {
  final String heading;
  final String body;
  final List<String> bullets;

  const RulesSection({
    required this.heading,
    this.body = '',
    this.bullets = const [],
  });
}

class RulesVariant {
  final String name;
  final String summary;

  const RulesVariant({required this.name, required this.summary});
}
