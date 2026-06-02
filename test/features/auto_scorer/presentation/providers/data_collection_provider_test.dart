import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to off when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(dataCollectionEnabledProvider.future), isFalse);
  });

  test('reads a stored opt-in', () async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(dataCollectionEnabledProvider.future), isTrue);
  });

  test('setEnabled persists and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(dataCollectionEnabledProvider.future);
    await container.read(dataCollectionEnabledProvider.notifier).setEnabled(true);
    expect(container.read(dataCollectionEnabledProvider).value, isTrue);

    // A fresh container reads back the persisted value.
    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(await reborn.read(dataCollectionEnabledProvider.future), isTrue);
  });
}
