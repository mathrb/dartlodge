import 'package:dart_lodge/core/game/dart_input_sink.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSink implements DartInputSink {
  final List<String> darts = [];
  final List<(double?, double?)> positions = [];
  int advances = 0;
  @override
  void submitDart(String segment, {double? x, double? y}) {
    darts.add(segment);
    positions.add((x, y));
  }

  @override
  void advanceTurn() => advances++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoScoringEnabled', () {
    test('defaults to off', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(autoScoringEnabledProvider.future), isFalse);
    });

    test('setEnabled persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(autoScoringEnabledProvider.future);
      await container.read(autoScoringEnabledProvider.notifier).setEnabled(true);
      expect(container.read(autoScoringEnabledProvider).value, isTrue);

      final reborn = ProviderContainer();
      addTearDown(reborn.dispose);
      expect(await reborn.read(autoScoringEnabledProvider.future), isTrue);
    });
  });

  group('ActiveTurnSignal', () {
    test('starts at 0 and bumps monotonically', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeTurnSignalProvider), 0);
      container.read(activeTurnSignalProvider.notifier).bump();
      container.read(activeTurnSignalProvider.notifier).bump();
      expect(container.read(activeTurnSignalProvider), 2);
    });
  });

  group('ActiveDartInputSink', () {
    test('starts null and binds/unbinds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeDartInputSinkProvider), isNull);

      final sink = _RecordingSink();
      container.read(activeDartInputSinkProvider.notifier).bind(sink);
      expect(container.read(activeDartInputSinkProvider), same(sink));

      container.read(activeDartInputSinkProvider.notifier).bind(null);
      expect(container.read(activeDartInputSinkProvider), isNull);
    });
  });
}
