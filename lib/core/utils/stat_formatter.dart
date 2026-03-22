class StatFormatter {
  static String fmtDouble(double? v, {int decimals = 1}) =>
      v != null ? v.toStringAsFixed(decimals) : '—';

  /// [isRatio] = true means v is 0.0–1.0 and needs ×100.
  /// false means v is already 0–100.
  static String fmtPct(double? v, {bool isRatio = true}) =>
      v != null ? '${(isRatio ? v * 100 : v).toStringAsFixed(1)}%' : '—';

  static String fmtInt(int? v) => v != null ? v.toString() : '—';

  static String fmtPerLeg(int total, int legsPlayed) =>
      legsPlayed == 0 ? '—' : (total / legsPlayed).toStringAsFixed(1);
}
