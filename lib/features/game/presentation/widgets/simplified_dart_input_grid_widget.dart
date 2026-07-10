import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import 'dot_row_widget.dart';

const _row1 = [1, 2, 3, 4, 5, 6, 7];
const _row2 = [8, 9, 10, 11, 12, 13, 14];
const _row3 = [15, 16, 17, 18, 19, 20];

/// Which multiplier the next number tap will apply.
enum _Armed { none, double, triple }

/// A forgiving alternative to [DartInputGridWidget] with fewer, larger targets,
/// laid out as four rows: `1–7`, `8–14`, `15–20` + an arm-aware **Bull** cell,
/// then **MISS** / **Double** / **Triple**. Opt-in via the simplified-input
/// setting; used on the X01 and Count-up board pages only. Emits the identical
/// segment strings (`'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`) as the
/// full grid, so the scoring engine is unchanged.
///
/// Interaction: tapping Double/Triple arms that multiplier (highlighted); the
/// next number tap yields the double/triple and disarms. With nothing armed a
/// number tap scores a single. The Bull cell follows the armed multiplier —
/// single bull (`'SB'`, 25) by default, double bull (`'DB'`, 50) when Double is
/// armed, and non-selectable when Triple is armed (there is no triple bull).
/// MISS always emits directly and clears any arm.
class SimplifiedDartInputGridWidget extends StatefulWidget {
  const SimplifiedDartInputGridWidget({
    required this.onSegmentTapped,
    this.enabled = true,
    super.key,
  });

  final void Function(String segment) onSegmentTapped;
  final bool enabled;

  @override
  State<SimplifiedDartInputGridWidget> createState() =>
      _SimplifiedDartInputGridWidgetState();
}

class _SimplifiedDartInputGridWidgetState
    extends State<SimplifiedDartInputGridWidget> {
  _Armed _armed = _Armed.none;

  /// Number of multiplier dots to draw under each number cell, reflecting the
  /// armed multiplier live: 1 for a single (default), 2 for double, 3 for
  /// triple. Diverges from the full grid (0 dots for singles) on purpose — the
  /// simplified cell is mode-dependent, so the single dot confirms "single mode".
  int get _dotCount => switch (_armed) {
        _Armed.none => 1,
        _Armed.double => 2,
        _Armed.triple => 3,
      };

  void _tapNumber(int n) {
    final prefix = switch (_armed) {
      _Armed.none => '',
      _Armed.double => 'D',
      _Armed.triple => 'T',
    };
    widget.onSegmentTapped('$prefix$n');
    if (_armed != _Armed.none) {
      setState(() => _armed = _Armed.none);
    }
  }

  void _tapSpecial(String segment) {
    widget.onSegmentTapped(segment);
    if (_armed != _Armed.none) {
      setState(() => _armed = _Armed.none);
    }
  }

  void _toggle(_Armed which) {
    setState(() => _armed = _armed == which ? _Armed.none : which);
  }

  @override
  void didUpdateWidget(SimplifiedDartInputGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear any armed multiplier when the keypad becomes disabled (turn ended
    // or bust). Otherwise the arm would silently carry into the next turn and
    // double/triple the player's first dart. A rebuild is already in flight, so
    // no setState is needed.
    if (!widget.enabled && _armed != _Armed.none) {
      _armed = _Armed.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          // Numbers 1–7, 8–14, then 15–20 + Bull (three rows of seven).
          Expanded(
            child: Column(
              children: [
                Expanded(child: _numberRow(_row1, cs)),
                const SizedBox(height: 4),
                Expanded(child: _numberRow(_row2, cs)),
                const SizedBox(height: 4),
                Expanded(child: _numberRow(_row3, cs, trailing: _bullCell(cs))),
              ],
            ),
          ),
          // MISS + armed multiplier toggles (equal thirds).
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _specialButton(
                    semanticLabel: 'Miss',
                    bgColor: cs.surfaceContainerLowest,
                    onTap: () => _tapSpecial('MISS'),
                    child: Text(
                      'MISS',
                      style: AppTextStyles.segmentButton
                          .copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _multiplierButton(
                    label: 'Double',
                    armed: _armed == _Armed.double,
                    onTap: () => _toggle(_Armed.double),
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _multiplierButton(
                    label: 'Triple',
                    armed: _armed == _Armed.triple,
                    onTap: () => _toggle(_Armed.triple),
                    cs: cs,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberRow(List<int> numbers, ColorScheme cs, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < numbers.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(child: _numberCell(numbers[i], cs)),
        ],
        if (trailing != null) ...[
          const SizedBox(width: 4),
          Expanded(child: trailing),
        ],
      ],
    );
  }

  Widget _numberCell(int n, ColorScheme cs) {
    return Semantics(
      label: '$n',
      child: InkWell(
        onTap: widget.enabled ? () => _tapNumber(n) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$n',
                style:
                    AppTextStyles.segmentButton.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              DotRow(
                count: _dotCount,
                color: cs.primaryFixed.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _multiplierButton({
    required String label,
    required bool armed,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Semantics(
      label: label,
      button: true,
      selected: armed,
      child: InkWell(
        onTap: widget.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: BoxDecoration(
            color: armed ? cs.primary : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: armed ? null : Border.all(color: cs.outlineVariant),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.segmentButton.copyWith(
              color: armed ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// The Bull cell on the third number row, arm-aware like a number: single
  /// bull by default, double bull when Double is armed, and non-selectable
  /// (greyed) when Triple is armed — there is no triple bull.
  Widget _bullCell(ColorScheme cs) {
    final disabled = _armed == _Armed.triple;

    final Color bgColor;
    final Widget child;
    switch (_armed) {
      case _Armed.double:
        bgColor = cs.primaryFixed;
        child = _bullLabel(
          '50',
          AppColors.onPrimaryFixed,
          AppColors.onPrimaryFixed,
          dots: 2,
        );
      case _Armed.triple:
        // No triple bull exists — the cell is greyed out and inert.
        bgColor = cs.surfaceContainerHighest;
        child = Text(
          'BULL',
          style: AppTextStyles.segmentButton
              .copyWith(color: cs.onSurface.withValues(alpha: 0.38)),
        );
      case _Armed.none:
        bgColor = cs.surfaceContainerHighest;
        child = _bullLabel(
          '25',
          cs.onSurface,
          cs.primaryFixed.withValues(alpha: 0.7),
          dots: 1,
        );
    }

    return Semantics(
      label: 'Bull',
      button: true,
      selected: _armed == _Armed.double,
      enabled: widget.enabled && !disabled,
      child: InkWell(
        onTap: widget.enabled && !disabled
            ? () => _tapSpecial(_armed == _Armed.double ? 'DB' : 'SB')
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _specialButton({
    required String semanticLabel,
    required Color bgColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Semantics(
      label: semanticLabel,
      child: InkWell(
        onTap: widget.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _bullLabel(
    String value,
    Color valueColor,
    Color subColor, {
    int dots = 0,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.segmentButton.copyWith(color: valueColor),
        ),
        Text(
          'BULL',
          style: AppTextStyles.multiplierLabel.copyWith(color: subColor),
        ),
        if (dots > 0) ...[
          const SizedBox(height: 4),
          DotRow(count: dots, color: subColor),
        ],
      ],
    );
  }
}
