import 'package:dart_lodge/features/auto_scorer/domain/model_update/staged_model_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the over-the-air model state (#715) in `shared_preferences`: the
/// description of the currently-staged model, and the version of one that was
/// rejected at native load (#785). Sole owner of these keys, so the download
/// pipeline and the resolver never disagree about what is staged, and so the
/// rejection outlives the process that observed it. The resolver has no use for
/// the rejection; the download pipeline and the settings row both read it.
/// Platform-agnostic
/// (SharedPreferences works on web too), but only exercised by the io service.
class StagedModelStore {
  final SharedPreferences _prefs;

  StagedModelStore(this._prefs);

  static const _kVersion = 'auto_scorer_staged_version';
  static const _kContract = 'auto_scorer_staged_contract';
  static const _kSha = 'auto_scorer_staged_sha';
  static const _kSize = 'auto_scorer_staged_size';
  static const _kQuarantined = 'auto_scorer_quarantined_version';

  /// The staged model, or null when nothing is staged (any key missing).
  StagedModelState? read() {
    final version = _prefs.getString(_kVersion);
    final contract = _prefs.getInt(_kContract);
    final sha = _prefs.getString(_kSha);
    final size = _prefs.getInt(_kSize);
    if (version == null || contract == null || sha == null || size == null) {
      return null;
    }
    return StagedModelState(
      version: version,
      contract: contract,
      sha256: sha,
      sizeBytes: size,
    );
  }

  Future<void> write(StagedModelState state) async {
    await _prefs.setString(_kVersion, state.version);
    await _prefs.setInt(_kContract, state.contract);
    await _prefs.setString(_kSha, state.sha256);
    await _prefs.setInt(_kSize, state.sizeBytes);
  }

  Future<void> clear() async {
    await _prefs.remove(_kVersion);
    await _prefs.remove(_kContract);
    await _prefs.remove(_kSha);
    await _prefs.remove(_kSize);
  }

  /// The model version that was downloaded, staged, then rejected because it
  /// would not load natively (#785). Kept so the updater does not fetch the
  /// same asset again on the next launch: [clear] alone would leave nothing to
  /// tell a rejected version apart from one never seen, and the download would
  /// repeat every launch.
  String? readQuarantined() => _prefs.getString(_kQuarantined);

  Future<void> writeQuarantined(String version) =>
      _prefs.setString(_kQuarantined, version);

  /// Dropped as soon as the manifest advertises a different version, so one bad
  /// model never blocks the ones published after it.
  Future<void> clearQuarantined() => _prefs.remove(_kQuarantined);
}
