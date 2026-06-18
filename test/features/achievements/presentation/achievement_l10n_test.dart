import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:dart_lodge/features/achievements/presentation/achievement_l10n.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Coverage guard (#526): every catalogue achievement resolves to a non-empty
/// localized title + description — i.e. no `switch` arm falls through to the raw
/// key. Mirrors `achievements_registry_test`.
void main() {
  test('every kAchievements id resolves to non-empty EN title + description',
      () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final a in kAchievements) {
      final title = achievementTitle(l10n, a);
      final desc = achievementDescription(l10n, a);
      expect(title, isNotEmpty, reason: '${a.id} title');
      expect(title, isNot(a.titleKey),
          reason: '${a.id} title fell through to the raw key');
      expect(desc, isNotEmpty, reason: '${a.id} description');
      expect(desc, isNot(a.descriptionKey),
          reason: '${a.id} description fell through to the raw key');
    }
  });
}
