import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/board_clear_wait.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'board_clear_wait_provider.g.dart';

const _kBoardClearWaitKey = 'auto_scorer_board_clear_wait';

/// The "Board-clear wait" preset (#800): how long the board must read empty
/// before auto-advance moves the turn on. Default [BoardClearWait.normal].
/// Only consulted when auto-advance is on (see [emptyFramesToRebaselineFor]);
/// snapshotted when an auto-scorer session starts.
@Riverpod(keepAlive: true)
class BoardClearWaitSetting extends _$BoardClearWaitSetting {
  @override
  Future<BoardClearWait> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final stored = prefs.getString(_kBoardClearWaitKey);
    return BoardClearWait.values.firstWhere(
      (w) => w.name == stored,
      orElse: () => BoardClearWait.normal,
    );
  }

  Future<void> setWait(BoardClearWait wait) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kBoardClearWaitKey, wait.name);
    state = AsyncData(wait);
  }
}
