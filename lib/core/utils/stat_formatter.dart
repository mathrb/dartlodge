class StatFormatter {
  static String _stripTrailingZeros(String s) {
    if (!s.contains('.')) return s;
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  static String fmtDouble(double? v, {int decimals = 1}) =>
      v != null ? _stripTrailingZeros(v.toStringAsFixed(decimals)) : '—';

  /// [isRatio] = true means v is 0.0–1.0 and needs ×100.
  /// false means v is already 0–100.
  /// [decimals] controls the precision of the rendered number; trailing zeros
  /// are always stripped, so `fmtPct(0.5, decimals: 0)` → `'50%'`.
  static String fmtPct(double? v, {bool isRatio = true, int decimals = 1}) =>
      v != null
          ? '${_stripTrailingZeros((isRatio ? v * 100 : v).toStringAsFixed(decimals))}%'
          : '—';

  static String fmtInt(int? v) => v != null ? v.toString() : '—';

  static String fmtPerLeg(int total, int legsPlayed) => legsPlayed == 0
      ? '—'
      : _stripTrailingZeros((total / legsPlayed).toStringAsFixed(1));
}
