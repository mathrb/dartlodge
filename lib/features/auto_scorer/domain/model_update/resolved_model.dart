/// Where the resolved model came from: the [bundled] app asset (the ultimate,
/// never-deleted fallback) or a [staged] over-the-air download on disk (#715).
/// Wire values are stable JSON strings so persistence/telemetry stay readable.
enum ModelOrigin {
  bundled('bundled'),
  staged('staged');

  const ModelOrigin(this.wire);

  final String wire;
}

/// The effective model for a scoring session: an absolute/asset [path] to feed
/// `YOLOView`, the [version] to stamp on captures, and its [origin]. Resolved
/// once at session start and passed as a prop so the model can never hot-swap
/// mid-game.
///
/// Pure domain — no Flutter, no dart:io. File existence and the persisted staged
/// state are checked by the data layer; this type only carries the outcome.
class ResolvedModel {
  final String path;
  final String version;
  final ModelOrigin origin;

  const ResolvedModel({
    required this.path,
    required this.version,
    required this.origin,
  });

  @override
  bool operator ==(Object other) =>
      other is ResolvedModel &&
      other.path == path &&
      other.version == version &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(path, version, origin);

  @override
  String toString() =>
      'ResolvedModel(path: $path, version: $version, origin: ${origin.wire})';
}
