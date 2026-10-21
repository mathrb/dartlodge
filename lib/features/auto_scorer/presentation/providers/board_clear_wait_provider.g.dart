// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_clear_wait_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The "Board-clear wait" preset (#800): how long the board must read empty
/// before auto-advance moves the turn on. Default [BoardClearWait.normal].
/// Only consulted when auto-advance is on (see [emptyFramesToRebaselineFor]);
/// snapshotted when an auto-scorer session starts.

@ProviderFor(BoardClearWaitSetting)
final boardClearWaitSettingProvider = BoardClearWaitSettingProvider._();

/// The "Board-clear wait" preset (#800): how long the board must read empty
/// before auto-advance moves the turn on. Default [BoardClearWait.normal].
/// Only consulted when auto-advance is on (see [emptyFramesToRebaselineFor]);
/// snapshotted when an auto-scorer session starts.
final class BoardClearWaitSettingProvider
    extends $AsyncNotifierProvider<BoardClearWaitSetting, BoardClearWait> {
  /// The "Board-clear wait" preset (#800): how long the board must read empty
  /// before auto-advance moves the turn on. Default [BoardClearWait.normal].
  /// Only consulted when auto-advance is on (see [emptyFramesToRebaselineFor]);
  /// snapshotted when an auto-scorer session starts.
  BoardClearWaitSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boardClearWaitSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boardClearWaitSettingHash();

  @$internal
  @override
  BoardClearWaitSetting create() => BoardClearWaitSetting();
}

String _$boardClearWaitSettingHash() =>
    r'6d264bb946b710f2588e599a9cf759fb24686d3b';

/// The "Board-clear wait" preset (#800): how long the board must read empty
/// before auto-advance moves the turn on. Default [BoardClearWait.normal].
/// Only consulted when auto-advance is on (see [emptyFramesToRebaselineFor]);
/// snapshotted when an auto-scorer session starts.

abstract class _$BoardClearWaitSetting extends $AsyncNotifier<BoardClearWait> {
  FutureOr<BoardClearWait> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BoardClearWait>, BoardClearWait>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BoardClearWait>, BoardClearWait>,
              AsyncValue<BoardClearWait>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
