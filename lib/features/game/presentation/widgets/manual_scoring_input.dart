import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/simplified_input_provider.dart';
import 'dart_input_grid_widget.dart';
import 'simplified_dart_input_grid_widget.dart';

/// Selects the manual dart-entry keypad based on the simplified-input setting:
/// the dense full [DartInputGridWidget] (default) or the forgiving
/// [SimplifiedDartInputGridWidget]. Exposes the same
/// `onSegmentTapped` / `enabled` API as either grid so board pages can swap in
/// place. Used wherever a full-board keypad is shown (#799): the in-board input
/// on X01 and Count-up, Catch 40 / Checkout Practice live entry, and the
/// correction and manual-entry sheets of every board except Cricket (which
/// keeps its own target-scoped sheets).
class ManualScoringInput extends ConsumerWidget {
  const ManualScoringInput({
    required this.onSegmentTapped,
    this.enabled = true,
    super.key,
  });

  final void Function(String segment) onSegmentTapped;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simplified = ref.watch(simplifiedInputEnabledProvider).value ?? false;
    return simplified
        ? SimplifiedDartInputGridWidget(
            onSegmentTapped: onSegmentTapped,
            enabled: enabled,
          )
        : DartInputGridWidget(
            onSegmentTapped: onSegmentTapped,
            enabled: enabled,
          );
  }
}
