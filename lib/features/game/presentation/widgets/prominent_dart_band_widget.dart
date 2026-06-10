import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

/// Large, at-distance-readable version of the 3-dart turn indicator, for
/// auto-scoring mode (#441 / epic #440).
///
/// In auto-scoring the phone is mounted near the board and the player stands at
/// the oche (~2.4 m), where the compact 12 pt badges in [GameStatusBarWidget]
/// are unreadable and too small to tap. This band renders the same three darts
/// prominently with large tap targets.
///
/// Presentational only: the correction / manual-entry UI and the wiring stay in
/// each board. The public API mirrors the trio the X01 / Cricket / Practice
/// boards already feed `GameStatusBarWidget` ([currentTurnDarts],
/// [onDartTapped], [tapEmptySlots]) so each camera-first layout can compose this
/// widget with no per-game branching. Manual-mode layouts keep the compact
/// status-bar indicator and do not use this band.
class ProminentDartBandWidget extends StatelessWidget {
  const ProminentDartBandWidget({
    required this.currentTurnDarts,
    this.onDartTapped,
    this.tapEmptySlots = false,
    super.key,
  });

  /// Segments thrown this turn. An empty string is the engine's "dart not
  /// thrown" sentinel (bust/checkout padding, #261) — rendered as an inert
  /// placeholder, never as a phantom MISS.
  final List<String> currentTurnDarts;

  /// Invoked with the 0-based slot index when a slot is tapped. A thrown slot
  /// means correction; an empty slot (only when [tapEmptySlots]) means manual
  /// entry of a dart the camera missed. Null disables all taps.
  final void Function(int index)? onDartTapped;

  /// Camera-first: make empty (not-yet-thrown) slots tappable so a missed dart
  /// can be entered manually. Default false keeps empty slots inert.
  final bool tapEmptySlots;

  /// The tap callback for slot [i], gated to match the status bar's rules: a
  /// thrown dart is tappable for correction; an empty slot is tappable only
  /// when [tapEmptySlots] is set; everything is inert when [onDartTapped] is
  /// null.
  VoidCallback? _tapFor(int i) {
    if (onDartTapped == null) return null;
    final thrown = currentTurnDarts.length > i && currentTurnDarts[i].isNotEmpty;
    if (thrown || tapEmptySlots) return () => onDartTapped!(i);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _DartSlot(
                segment:
                    currentTurnDarts.length > i ? currentTurnDarts[i] : '',
                tapEmptySlots: tapEmptySlots,
                onTap: _tapFor(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single large dart slot: a filled badge for a thrown dart, an "enter dart"
/// affordance for a tappable empty slot, or an inert placeholder otherwise.
class _DartSlot extends StatelessWidget {
  const _DartSlot({
    required this.segment,
    required this.tapEmptySlots,
    this.onTap,
  });

  /// '' = not thrown.
  final String segment;
  final bool tapEmptySlots;

  /// Already gated by the parent; null means this slot is inert.
  final VoidCallback? onTap;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    Widget tappable(Widget child) => onTap == null
        ? child
        : InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: AppTheme.kineticSplashColor,
            highlightColor: AppTheme.kineticSplashColor,
            child: child,
          );

    if (segment.isNotEmpty) {
      return tappable(
        Container(
          height: _height,
          decoration: BoxDecoration(
            color:
                cs.primaryFixed.withValues(alpha: AppTheme.opacityGhostBorderLight),
            borderRadius: radius,
            border: Border.all(
              color: cs.primaryFixed
                  .withValues(alpha: AppTheme.opacityGhostBorderStrong),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                segment,
                maxLines: 1,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: cs.primaryFixed,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Empty slot — tappable manual entry, or inert placeholder.
    final tappableEmpty = tapEmptySlots && onTap != null;
    return tappable(
      Container(
        height: _height,
        decoration: BoxDecoration(
          color: tappableEmpty
              ? cs.surfaceContainer
              : cs.surfaceContainer
                  .withValues(alpha: AppTheme.opacityGhostBorderLight),
          borderRadius: radius,
          border: Border.all(
            color: cs.outlineVariant.withValues(
              alpha: tappableEmpty
                  ? AppTheme.opacityGhostBorderStrong
                  : AppTheme.opacityGhostBorderLight,
            ),
          ),
        ),
        child: tappableEmpty
            ? Icon(
                Icons.add_circle_outline,
                size: 28,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                semanticLabel: 'enter dart',
              )
            : Icon(
                Icons.more_horiz,
                size: 24,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                semanticLabel: 'dart not thrown',
              ),
      ),
    );
  }
}
