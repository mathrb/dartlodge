import 'package:dart_lodge/features/auto_scorer/presentation/providers/setup_tips_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to not-seen when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(autoScorerSetupTipsSeenProvider.future), isFalse);
  });

  test('reads a stored seen flag', () async {
    SharedPreferences.setMockInitialValues({'auto_scorer_setup_tips_seen': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(autoScorerSetupTipsSeenProvider.future), isTrue);
  });

  test('setSeen persists and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(autoScorerSetupTipsSeenProvider.future);
    await container.read(autoScorerSetupTipsSeenProvider.notifier).setSeen(true);
    expect(container.read(autoScorerSetupTipsSeenProvider).value, isTrue);

    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(await reborn.read(autoScorerSetupTipsSeenProvider.future), isTrue);
  });
}
