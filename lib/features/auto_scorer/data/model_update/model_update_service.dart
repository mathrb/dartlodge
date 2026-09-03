import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';

/// The lifecycle state of the over-the-air model channel (#715), surfaced in
/// settings. Kept formatting-free (no strings) so the presentation layer maps it
/// to localized text.
enum ModelUpdateStatus {
  /// The active model is the newest the manifest knows about (or OTA is
  /// unsupported on this platform / build).
  upToDate,

  /// A background check/download is in flight.
  downloading,

  /// A newer model finished staging and applies at the next session.
  updateReady,

  /// The last check could not complete (offline, HTTP error, or an asset whose
  /// size/hash did not match the manifest). The active model is unchanged; the
  /// next launch retries. Distinct from [upToDate] so the settings row stops
  /// reporting a failed check as a successful one (#782).
  checkFailed,
}

/// Resolves and updates the auto-scorer detection model out-of-band (#715).
///
/// Mobile-io implementation downloads/verifies/stages a model; the web stub is a
/// no-op that always returns the bundled model. Obtain one via
/// [openModelUpdateService] (conditionally imported per platform).
abstract class ModelUpdateService {
  /// False on the web stub / where OTA is unavailable — callers still get a
  /// valid bundled [resolve] result.
  bool get isSupported;

  /// The effective model for the next session (staged if valid, else bundled).
  /// Never throws — any failure resolves to the bundled asset.
  Future<ResolvedModel> resolve();

  /// Background check: fetch the manifest, and if a compatible newer model is
  /// available on an unmetered connection, download + verify + stage it for the
  /// next session. Silent and best-effort — never throws.
  Future<void> checkAndStage();

  /// Delete a staged model that failed to load natively and clear its persisted
  /// state, so the resolver falls back to bundled and never retries it.
  Future<void> quarantine(String version);

  /// The current lifecycle status for the settings row.
  ModelUpdateStatus get status;
}
