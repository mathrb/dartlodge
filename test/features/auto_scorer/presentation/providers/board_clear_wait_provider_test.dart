import 'package:dart_lodge/features/auto_scorer/domain/tracking/board_clear_wait.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/board_clear_wait_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BoardClearWait> readWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container.read(boardClearWaitSettingProvider.future);
  }

  test('defaults to normal when nothing stored', () async {
    expect(await readWith({}), BoardClearWait.normal);
  });

  test('reads a stored preset', () async {
    expect(await readWith({'auto_scorer_board_clear_wait': 'fast'}),
        BoardClearWait.fast);
  });

  test('an unknown stored value falls back to normal', () async {
    expect(await readWith({'auto_scorer_board_clear_wait': 'turbo'}),
        BoardClearWait.normal);
  });

  test('setWait persists and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(boardClearWaitSettingProvider.future);
    await container
        .read(boardClearWaitSettingProvider.notifier)
        .setWait(BoardClearWait.safe);
    expect(container.read(boardClearWaitSettingProvider).value,
        BoardClearWait.safe);

    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(await reborn.read(boardClearWaitSettingProvider.future),
        BoardClearWait.safe);
  });
}
