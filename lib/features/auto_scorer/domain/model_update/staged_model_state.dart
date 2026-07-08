/// The persisted description of a staged over-the-air model (#715) — what the
/// app wrote to `shared_preferences` after a successful download + verify. Kept
/// as a pure value type (no dart:io / no prefs) so the resolver rule in
/// [selectModel] is unit-testable without a filesystem or platform.
///
/// [contract] is stored alongside so a later app version with a bumped
/// `kAutoScorerModelContract` can recognise this staged model as incompatible
/// and fall back to the bundled asset without ever loading it.
class StagedModelState {
  final String version;
  final int contract;
  final String sha256;
  final int sizeBytes;

  const StagedModelState({
    required this.version,
    required this.contract,
    required this.sha256,
    required this.sizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      other is StagedModelState &&
      other.version == version &&
      other.contract == contract &&
      other.sha256 == sha256 &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(version, contract, sha256, sizeBytes);
}
