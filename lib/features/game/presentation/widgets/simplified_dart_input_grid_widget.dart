import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

const _row1 = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11];
const _row2 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

/// Which multiplier the next number tap will apply.
enum _Armed { none, double, triple }

/// A forgiving alternative to [DartInputGridWidget] with fewer, larger targets:
/// the 20 numbers plus "armed" **Double** / **Triple** multiplier buttons and
/// the same MISS / 25 / 50 specials. Opt-in via the simplified-input setting;
/// used on the X01 and Count-up board pages only. Emits the identical segment
/// strings (`'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`) as the full grid,
/// so the scoring engine is unchanged.
///
/// Interaction: tapping Double/Triple arms that multiplier (highlighted); the
/// next number tap yields the double/triple and disarms. With nothing armed a
/// number tap scores a single. Specials always emit directly and clear any arm.
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
          // Numbers 20–11 then 10–1 (two tall rows of 10).
          Expanded(
            child: Column(
              children: [
                Expanded(child: _numberRow(_row1, cs)),
                const SizedBox(height: 4),
                Expanded(child: _numberRow(_row2, cs)),
              ],
            ),
          ),
          // Armed multiplier toggles.
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
          // Specials — identical to the full grid.
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
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
                  flex: 3,
                  child: _specialButton(
                    semanticLabel: 'Single Bull',
                    bgColor: cs.surfaceContainerHighest,
                    onTap: () => _tapSpecial('SB'),
                    child: _bullLabel(
                      '25',
                      cs.onSurface,
                      cs.primaryFixed.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: _specialButton(
                    semanticLabel: 'Double Bull',
                    bgColor: cs.primaryFixed,
                    onTap: () => _tapSpecial('DB'),
                    child: _bullLabel(
                      '50',
                      AppColors.onPrimaryFixed,
                      AppColors.onPrimaryFixed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberRow(List<int> numbers, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < numbers.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(child: _numberCell(numbers[i], cs)),
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
          child: Text(
            '$n',
            style: AppTextStyles.segmentButton.copyWith(color: cs.onSurface),
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

  Widget _bullLabel(String value, Color valueColor, Color subColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.segmentButton.copyWith(color: valueColor),
        ),
        Text(
          'BULL',
          style: AppTextStyles.multiplierLabel.copyWith(color: subColor),
        ),
      ],
    );
  }
}
