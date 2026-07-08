/// The out-of-band model manifest (#715): a tiny JSON document committed on
/// `main` and served over HTTPS from a pinned GitHub host. It points the app at
/// the latest detection-model release asset and carries everything the app needs
/// to gate compatibility and verify integrity before staging a download.
///
/// The binary itself is a GitHub Release asset (never committed to git); [url]
/// is the versioned download URL. The manifest URL is stable (updated per model
/// publication); the asset URL is versioned.
///
/// JSON is hand-parsed (mirroring [CaptureRecord]) with back-compat-tolerant
/// defaults and stable snake_case wire keys, so adding fields later (e.g. an iOS
/// `.mlpackage` channel) stays additive.
///
/// The wire keys are **snake_case** (`model_version`, `size_bytes`, `input_size`,
/// `class_count`) — this is the canonical contract the publishing script must
/// emit, and it supersedes the camelCase example in the #715 design comment. The
/// committed `model_manifest.json` at the repo root is the reference document.
class AutoScorerModelManifest {
  /// Manifest envelope version — lets the parser evolve the shape itself.
  final int schema;

  /// The model compatibility contract this binary was produced for. Compared
  /// strictly against `kAutoScorerModelContract` at gate time.
  final int contract;

  /// Stem of the model (e.g. `dart_round26_withcal`), stamped as `model_version`
  /// on captures produced by it.
  final String modelVersion;

  /// HTTPS download URL of the versioned release asset.
  final String url;

  /// Lowercase hex SHA-256 of the binary, verified against the downloaded bytes.
  final String sha256;

  /// Expected byte length of the binary (a cheap secondary integrity check).
  final int sizeBytes;

  /// Model input edge in pixels (sanity gate: must be 800).
  final int inputSize;

  /// Number of detection classes (sanity gate: must be 5 — dart + 4 cal points).
  final int classCount;

  /// Binary format. `tflite` is the only Android channel today; a future iOS
  /// `mlpackage` channel is additive. Defaults to `tflite` for forward-compat.
  final String format;

  const AutoScorerModelManifest({
    required this.schema,
    required this.contract,
    required this.modelVersion,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
    required this.inputSize,
    required this.classCount,
    this.format = 'tflite',
  });

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'contract': contract,
        'model_version': modelVersion,
        'url': url,
        'sha256': sha256,
        'size_bytes': sizeBytes,
        'input_size': inputSize,
        'class_count': classCount,
        'format': format,
      };

  /// Parses a manifest, tolerating unknown keys and a missing `format` (older
  /// manifests predate the iOS channel and are `tflite`). Throws only when a
  /// load-bearing key is absent or the wrong type — an unparseable manifest is
  /// treated by callers as "no update available" (keep the bundled model).
  factory AutoScorerModelManifest.fromJson(Map<String, dynamic> json) {
    return AutoScorerModelManifest(
      schema: (json['schema'] as num).toInt(),
      contract: (json['contract'] as num).toInt(),
      modelVersion: json['model_version'] as String,
      url: json['url'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      inputSize: (json['input_size'] as num).toInt(),
      classCount: (json['class_count'] as num).toInt(),
      format: json['format'] as String? ?? 'tflite',
    );
  }
}
