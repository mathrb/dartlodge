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
  static String fmtPct(double? v, {bool isRatio = true}) => v != null
      ? '${_stripTrailingZeros((isRatio ? v * 100 : v).toStringAsFixed(1))}%'
      : '—';

  static String fmtInt(int? v) => v != null ? v.toString() : '—';

  static String fmtPerLeg(int total, int legsPlayed) => legsPlayed == 0
      ? '—'
      : _stripTrailingZeros((total / legsPlayed).toStringAsFixed(1));
}
