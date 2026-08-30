import 'package:dart_lodge/features/auto_scorer/presentation/providers/technical_display_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The technical display (#738) is a debug opt-in: the plain preview is what a
/// player gets unless they deliberately turn the raw detection boxes back on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to off when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
        await container.read(autoScorerTechnicalDisplayProvider.future), isFalse);
  });

  test('reads a stored opt-in', () async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_technical_display': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
        await container.read(autoScorerTechnicalDisplayProvider.future), isTrue);
  });

  test('setEnabled persists and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(autoScorerTechnicalDisplayProvider.future);
    await container
        .read(autoScorerTechnicalDisplayProvider.notifier)
        .setEnabled(true);
    expect(container.read(autoScorerTechnicalDisplayProvider).value, isTrue);

    // A fresh container reads back the persisted value.
    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(
        await reborn.read(autoScorerTechnicalDisplayProvider.future), isTrue);
  });
}
