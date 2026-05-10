/// Display formatters for player / competitor names.
class NameFormatter {
  const NameFormatter._();

  /// Returns "Alice" for single-name input, otherwise "First L." (first name +
  /// last initial). Used in dense tables where full names would not fit.
  static String shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return name;
    return '${parts.first} ${parts.last[0]}.';
  }
}
