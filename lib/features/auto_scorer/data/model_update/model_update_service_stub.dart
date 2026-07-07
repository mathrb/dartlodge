import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web stub for [ModelUpdateService] (#715): the auto-scorer is invisible on web,
/// so this no-op always resolves the bundled model and never downloads. Keeps
/// `flutter run -d chrome` building without dart:io.
class _UnsupportedModelUpdateService implements ModelUpdateService {
  const _UnsupportedModelUpdateService();

  @override
  bool get isSupported => false;

  @override
  ModelUpdateStatus get status => ModelUpdateStatus.upToDate;

  @override
  Future<ResolvedModel> resolve() async => const ResolvedModel(
        path: kAutoScorerModelAsset,
        version: kAutoScorerModelVersion,
        origin: ModelOrigin.bundled,
      );

  @override
  Future<void> checkAndStage() async {}

  @override
  Future<void> quarantine(String version) async {}
}

Future<ModelUpdateService> openModelUpdateService(SharedPreferences prefs) async =>
    const _UnsupportedModelUpdateService();
