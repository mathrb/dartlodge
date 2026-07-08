import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/core/settings/simplified_input_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer();

  group('SimplifiedInputEnabled.build()', () {
    test('defaults to false (dense grid stays default) when nothing stored',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(simplifiedInputEnabledProvider.future),
        isFalse,
      );
    });

    test('reads a stored true', () async {
      SharedPreferences.setMockInitialValues({kSimplifiedInputPrefKey: true});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(simplifiedInputEnabledProvider.future),
        isTrue,
      );
    });
  });

  group('SimplifiedInputEnabled.setEnabled()', () {
    test('persists true so it survives a rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(simplifiedInputEnabledProvider.future);
      await container
          .read(simplifiedInputEnabledProvider.notifier)
          .setEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kSimplifiedInputPrefKey), isTrue);

      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(
        await container2.read(simplifiedInputEnabledProvider.future),
        isTrue,
      );
    });
  });
}
