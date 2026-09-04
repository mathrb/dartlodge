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

  /// A model downloaded and verified, then failed to load natively when the
  /// session that would have used it started. It has been discarded and will
  /// not be fetched again; the bundled model stays in use. Distinct from
  /// [checkFailed] because nothing about the check failed (#785).
  updateRejected,
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

  /// Delete a staged model and clear its persisted state, so the resolver falls
  /// back to bundled and never loads that file again.
  ///
  /// [remember] additionally records the version so the *updater* never fetches
  /// it again;
  /// leave it true for a real rejection. The contract-bump housekeeping inside
  /// `checkAndStage` passes false: dropping a model made stale by a new app
  /// version is not a verdict on that model, which may well be republished for
  /// the new contract under the same version string.
  Future<void> quarantine(String version, {bool remember = true});

  /// What this process last observed: the verdict of a [checkAndStage] run, or
  /// a rejection recorded by [quarantine] (which the board calls when a staged
  /// model fails to load, outside any check), or the initial value when neither
  /// has happened. Read it to publish a verdict just reached; for what is
  /// actually installed, use [restingStatus].
  ModelUpdateStatus get status;

  /// The status implied by what is on disk right now, with no network check: a
  /// recorded rejection, a staged model pending, or nothing to report.
  ///
  /// The settings row is built from this rather than from [status], so it
  /// describes what is installed instead of stating a verdict no check ever
  /// reached — which is what happened on every launch with auto-scoring off,
  /// since the launch check is gated on that switch (#786).
  Future<ModelUpdateStatus> restingStatus();
}
