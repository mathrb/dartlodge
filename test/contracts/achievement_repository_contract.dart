// Achievement Repository Contract Tests (#521/#522)
//
// Backend-agnostic suite for any AchievementRepository implementation. FK
// parents (player, game) are seeded via the injected callbacks so the suite
// stays free of drift specifics.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/achievements/domain/repositories/achievement_repository.dart';

void runAchievementRepositoryContractTests(
  Future<AchievementRepository> Function() factory, {
  required Future<void> Function(String playerId) seedPlayer,
  required Future<void> Function(String gameId) seedGame,
}) {
  late AchievementRepository repo;

  setUp(() async {
    repo = await factory();
  });

  group('getUnlocked', () {
    test('returns an empty set when the player has unlocked nothing', () async {
      await seedPlayer('p1');
      expect(await repo.getUnlocked('p1'), isEmpty);
    });

    test('returns the unlocked ids after recordUnlock', () async {
      await seedPlayer('p1');
      await repo.recordUnlock('p1', 'first_180', DateTime.now());
      await repo.recordUnlock('p1', 'big_fish', DateTime.now());
      expect(await repo.getUnlocked('p1'), {'first_180', 'big_fish'});
    });

    test('is scoped per player', () async {
      await seedPlayer('p1');
      await seedPlayer('p2');
      await repo.recordUnlock('p1', 'first_180', DateTime.now());
      expect(await repo.getUnlocked('p2'), isEmpty);
    });
  });

  group('recordUnlock', () {
    test('is idempotent: recording the same id twice keeps one row', () async {
      await seedPlayer('p1');
      await repo.recordUnlock('p1', 'first_180', DateTime(2026, 1, 1));
      // Second call must not throw and must not duplicate the unlock.
      await repo.recordUnlock('p1', 'first_180', DateTime(2026, 2, 2));
      expect(await repo.getUnlocked('p1'), {'first_180'});
    });

    test('credits the optional gameId', () async {
      await seedPlayer('p1');
      await seedGame('g1');
      await repo.recordUnlock('p1', 'nine_darter', DateTime.now(),
          gameId: 'g1');
      expect(await repo.getUnlocked('p1'), {'nine_darter'});
    });

    test('surfaces an FK violation (unknown player) as a RepositoryException',
        () async {
      await expectLater(
        () => repo.recordUnlock('ghost', 'first_180', DateTime.now()),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('surfaces an FK violation (unknown gameId) as a RepositoryException',
        () async {
      await seedPlayer('p1');
      await expectLater(
        () => repo.recordUnlock('p1', 'first_180', DateTime.now(),
            gameId: 'ghost-game'),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('watchUnlocked', () {
    test('emits the current set, then re-emits after a new unlock', () async {
      await seedPlayer('p1');

      final emissions = <Set<String>>[];
      final sub = repo.watchUnlocked('p1').listen(emissions.add);
      await pumpEventQueue(times: 50);

      await repo.recordUnlock('p1', 'first_180', DateTime.now());
      await pumpEventQueue(times: 50);

      await sub.cancel();

      expect(emissions.first, isEmpty, reason: 'initial empty set');
      expect(emissions.last, {'first_180'}, reason: 'reactive update');
    });
  });

  group('watchUnlockedDetails', () {
    test('emits the id → unlockedAt map, reactively, with the date round-trip',
        () async {
      await seedPlayer('p1');
      final at = DateTime(2026, 1, 2, 3, 4, 5);

      final emissions = <Map<String, DateTime>>[];
      final sub = repo.watchUnlockedDetails('p1').listen(emissions.add);
      await pumpEventQueue(times: 50);

      await repo.recordUnlock('p1', 'first_180', at);
      await pumpEventQueue(times: 50);

      await sub.cancel();

      expect(emissions.first, isEmpty, reason: 'initial empty map');
      expect(emissions.last, {'first_180': at},
          reason: 'reactive update with the persisted date');
    });
  });
}
