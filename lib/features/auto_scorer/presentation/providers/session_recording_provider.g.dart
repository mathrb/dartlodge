// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The session-recording opt-in (#490): persist the detection trace (detection
/// boxes, no photos) so a scoring bug can be replayed off-device. Default
/// **off** — off means zero trace files are written. A distinct provider from
/// [DataCollectionEnabled] (different pipeline), but since #686 a single
/// "Record for debugging & training" Settings toggle drives both together (see
/// `_setRecording`), so enabling recording also enables photo capture.

@ProviderFor(SessionRecordingEnabled)
final sessionRecordingEnabledProvider = SessionRecordingEnabledProvider._();

/// The session-recording opt-in (#490): persist the detection trace (detection
/// boxes, no photos) so a scoring bug can be replayed off-device. Default
/// **off** — off means zero trace files are written. A distinct provider from
/// [DataCollectionEnabled] (different pipeline), but since #686 a single
/// "Record for debugging & training" Settings toggle drives both together (see
/// `_setRecording`), so enabling recording also enables photo capture.
final class SessionRecordingEnabledProvider
    extends $AsyncNotifierProvider<SessionRecordingEnabled, bool> {
  /// The session-recording opt-in (#490): persist the detection trace (detection
  /// boxes, no photos) so a scoring bug can be replayed off-device. Default
  /// **off** — off means zero trace files are written. A distinct provider from
  /// [DataCollectionEnabled] (different pipeline), but since #686 a single
  /// "Record for debugging & training" Settings toggle drives both together (see
  /// `_setRecording`), so enabling recording also enables photo capture.
  SessionRecordingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRecordingEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRecordingEnabledHash();

  @$internal
  @override
  SessionRecordingEnabled create() => SessionRecordingEnabled();
}

String _$sessionRecordingEnabledHash() =>
    r'85e2becec3e9ea4851519a5cb16816dc538a8a24';

/// The session-recording opt-in (#490): persist the detection trace (detection
/// boxes, no photos) so a scoring bug can be replayed off-device. Default
/// **off** — off means zero trace files are written. A distinct provider from
/// [DataCollectionEnabled] (different pipeline), but since #686 a single
/// "Record for debugging & training" Settings toggle drives both together (see
/// `_setRecording`), so enabling recording also enables photo capture.

abstract class _$SessionRecordingEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The on-device session-trace store (file-backed on mobile, no-op on web).
/// Consumers gate on [SessionTraceStore.isSupported] before recording.

@ProviderFor(sessionTraceStore)
final sessionTraceStoreProvider = SessionTraceStoreProvider._();

/// The on-device session-trace store (file-backed on mobile, no-op on web).
/// Consumers gate on [SessionTraceStore.isSupported] before recording.

final class SessionTraceStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionTraceStore>,
          SessionTraceStore,
          FutureOr<SessionTraceStore>
        >
    with
        $FutureModifier<SessionTraceStore>,
        $FutureProvider<SessionTraceStore> {
  /// The on-device session-trace store (file-backed on mobile, no-op on web).
  /// Consumers gate on [SessionTraceStore.isSupported] before recording.
  SessionTraceStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionTraceStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionTraceStoreHash();

  @$internal
  @override
  $FutureProviderElement<SessionTraceStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionTraceStore> create(Ref ref) {
    return sessionTraceStore(ref);
  }
}

String _$sessionTraceStoreHash() => r'2cf0dfd92ee10b600af33781fe30841d4353dd5f';
