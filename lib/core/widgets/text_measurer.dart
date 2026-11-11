import 'package:flutter/widgets.dart';

/// Single-line text widths at the ambient text scale, with each style
/// merged over the ambient [DefaultTextStyle] the same way [Text] does
/// (e.g. Material's default letterSpacing).
///
/// Used by layouts that pick a shape (side by side vs stacked) from the
/// width their text needs at large system text sizes (DESIGN_SYSTEM §13).
class TextMeasurer {
  TextMeasurer(this.defaultStyle, this.textScaler, this.textDirection);

  /// Reads the ambient default style, text scaler and direction.
  factory TextMeasurer.of(BuildContext context) => TextMeasurer(
        DefaultTextStyle.of(context).style,
        MediaQuery.textScalerOf(context),
        Directionality.of(context),
      );

  final TextStyle defaultStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;

  double width(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: defaultStyle.merge(style)),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  /// Width of the widest space-separated word: the narrowest box [text] can
  /// wrap into without breaking a word.
  double widestWord(String text, TextStyle? style) {
    var widest = 0.0;
    for (final word in text.split(' ')) {
      if (word.isEmpty) continue;
      final w = width(word, style);
      if (w > widest) widest = w;
    }
    return widest;
  }
}
