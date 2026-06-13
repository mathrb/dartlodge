import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to off when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
        await container.read(sessionRecordingEnabledProvider.future), isFalse);
  });

  test('reads a stored opt-in', () async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_record_sessions': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(sessionRecordingEnabledProvider.future), isTrue);
  });

  test('setEnabled persists and survives a fresh container', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(sessionRecordingEnabledProvider.future);
    await container
        .read(sessionRecordingEnabledProvider.notifier)
        .setEnabled(true);
    expect(container.read(sessionRecordingEnabledProvider).value, isTrue);

    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(await reborn.read(sessionRecordingEnabledProvider.future), isTrue);
  });
}
