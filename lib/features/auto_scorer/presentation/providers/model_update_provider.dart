import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Web-guarded: the dart:io-backed service is swapped for a no-op stub on web so
// `flutter run -d chrome` builds without dart:io (#715).
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service_io.dart';

part 'model_update_provider.g.dart';

/// The over-the-air model-update service (dart:io on mobile, no-op on web, #715).
@Riverpod(keepAlive: true)
Future<ModelUpdateService> modelUpdateService(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return openModelUpdateService(prefs);
}

/// The effective model for the next session — a staged download if valid, else
/// the bundled asset. Resolved once and read as a snapshot at session start
/// (never live-watched into a running `YOLOView`, to avoid a mid-game reload).
/// Invalidate this after staging/quarantine so the next session picks it up.
@Riverpod(keepAlive: true)
Future<ResolvedModel> resolvedModel(Ref ref) async {
  final service = await ref.watch(modelUpdateServiceProvider.future);
  return service.resolve();
}

/// Drives + exposes the OTA lifecycle for the settings row and the launch host.
/// State is the current [ModelUpdateStatus]; [checkNow] runs a background check
/// (shared by the launch host and the "Check now" button) and refreshes
/// [resolvedModelProvider] so a newly staged model applies at the next session.
@Riverpod(keepAlive: true)
class ModelUpdateController extends _$ModelUpdateController {
  /// Describes what is installed, not what was last checked: with auto-scoring
  /// off the launch check never runs, and reading the in-memory [status] made
  /// the row state "up to date" having judged nothing, while a staged model
  /// could be waiting (#786). [checkNow] still publishes a real check's verdict.
  @override
  Future<ModelUpdateStatus> build() async {
    final service = await ref.watch(modelUpdateServiceProvider.future);
    return service.restingStatus();
  }

  /// Best-effort background check + stage. The service never throws; state
  /// reflects downloading → up-to-date/update-ready/check-failed/update-rejected.
  /// A newly staged model is picked up at the next session via the
  /// [resolvedModelProvider] invalidation.
  Future<void> checkNow() async {
    final service = await ref.read(modelUpdateServiceProvider.future);
    if (!service.isSupported) return;
    state = const AsyncData(ModelUpdateStatus.downloading);
    await service.checkAndStage();
    ref.invalidate(resolvedModelProvider);
    state = AsyncData(service.status);
  }
}
