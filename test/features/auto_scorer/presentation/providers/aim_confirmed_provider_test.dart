import 'package:dart_lodge/features/auto_scorer/presentation/providers/aim_confirmed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoScorerAimConfirmed (#687)', () {
    test('defaults to false (aim shown on the first camera start)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(autoScorerAimConfirmedProvider), isFalse);
    });

    test('set(true) flips it so the next start can skip the aim view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autoScorerAimConfirmedProvider.notifier).set(true);
      expect(container.read(autoScorerAimConfirmedProvider), isTrue);
    });

    test('is in-memory: a fresh container resets to false (app-restart semantics)',
        () {
      final first = ProviderContainer();
      first.read(autoScorerAimConfirmedProvider.notifier).set(true);
      expect(first.read(autoScorerAimConfirmedProvider), isTrue);
      first.dispose();

      // A new container models a fresh app run — the flag is not persisted.
      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(autoScorerAimConfirmedProvider), isFalse);
    });
  });
}
