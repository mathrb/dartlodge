import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metric.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage guard for the v1 achievement catalogue (#523), mirroring
/// `rules_registry_test`: the registry is the single source of truth, and CI
/// fails if an id is added/removed/duplicated or a definition is malformed.
void main() {
  // The locked v1 catalogue (design §2). Update this set deliberately when the
  // catalogue changes — it is the contract the registry must satisfy.
  const expectedIds = {
    'first_180', 'big_fish', 'first_win', 'nine_darter',
    'darts_1000', 'darts_10000', 'darts_50000',
    'count_180_10', 'count_180_50', 'count_180_100',
    'games_501_100', 'games_501_500',
    'wins_10', 'wins_50', 'wins_100',
  };

  group('kAchievements registry', () {
    test('contains exactly the locked v1 catalogue (no missing / extra ids)', () {
      expect(kAchievements.map((a) => a.id).toSet(), expectedIds);
    });

    test('ids are unique', () {
      final ids = kAchievements.map((a) => a.id).toList();
      expect(ids.length, ids.toSet().length);
      expect(ids.length, expectedIds.length);
    });

    test('every entry has non-empty title and description l10n keys', () {
      for (final a in kAchievements) {
        expect(a.titleKey, isNotEmpty, reason: '${a.id} titleKey');
        expect(a.descriptionKey, isNotEmpty, reason: '${a.id} descriptionKey');
      }
    });

    test('title and description keys are unique across the catalogue', () {
      final titleKeys = kAchievements.map((a) => a.titleKey).toList();
      final descKeys = kAchievements.map((a) => a.descriptionKey).toList();
      expect(titleKeys.length, titleKeys.toSet().length, reason: 'titleKeys');
      expect(descKeys.length, descKeys.toSet().length, reason: 'descriptionKeys');
    });

    test('counters carry a positive threshold', () {
      for (final a in kAchievements.where((a) => a.kind == AchievementKind.counter)) {
        expect(a.threshold, isNotNull, reason: '${a.id} is a counter');
        expect(a.threshold!, greaterThan(0), reason: '${a.id} threshold');
      }
    });

    test('any explicit threshold is positive (covers big_fish=170)', () {
      for (final a in kAchievements.where((a) => a.threshold != null)) {
        expect(a.threshold!, greaterThan(0), reason: '${a.id} threshold');
      }
      // big_fish is the lone binary carrying an explicit threshold.
      final bigFish = kAchievements.firstWhere((a) => a.id == 'big_fish');
      expect(bigFish.kind, AchievementKind.binary);
      expect(bigFish.threshold, 170);
    });

    test('big_fish is the ONLY binary with an explicit threshold', () {
      final binariesWithThreshold = kAchievements
          .where((a) => a.kind == AchievementKind.binary && a.threshold != null)
          .map((a) => a.id)
          .toList();
      expect(binariesWithThreshold, ['big_fish']);
    });

    test('hasNineDarter metric is only used by binary achievements', () {
      // A counter on a bool metric (always 0/1) makes no semantic sense.
      final users = kAchievements
          .where((a) => a.metric == AchievementMetric.hasNineDarter);
      expect(users, isNotEmpty);
      expect(users.every((a) => a.kind == AchievementKind.binary), isTrue);
    });
  });
}
