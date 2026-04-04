import 'package:flutter/material.dart';

/// A shared loading widget for `AsyncValue.when()` loading branches.
///
/// Renders a centered [CircularProgressIndicator]. When [height] is provided
/// the widget is constrained to that height (useful inside sections/charts).
/// When [color] is provided it overrides the default theme color.
class LoadingSpinnerWidget extends StatelessWidget {
  final double? height;
  final Color? color;

  const LoadingSpinnerWidget({super.key, this.height, this.color});

  @override
  Widget build(BuildContext context) {
    final spinner = Center(child: CircularProgressIndicator(color: color));
    if (height != null) {
      return SizedBox(height: height, child: spinner);
    }
    return spinner;
  }
}
