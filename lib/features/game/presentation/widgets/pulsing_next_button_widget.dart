import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_theme.dart';

/// Primary "NEXT PLAYER / NEXT ROUND / NEXT TARGET" button.
///
/// When [pulse] is true, the button breathes (scale + glow oscillates) to
/// signal that pressing it is the user's next required action — typically
/// when the turn has ended (3 darts thrown or bust) and dart input is
/// locked. Honors [MediaQuery.disableAnimationsOf] so widget tests using
/// `pumpAndSettle` aren't blocked by the indefinite repeat.
class PulsingNextButtonWidget extends StatefulWidget {
  const PulsingNextButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    required this.pulse,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool pulse;

  @override
  State<PulsingNextButtonWidget> createState() =>
      _PulsingNextButtonWidgetState();
}

class _PulsingNextButtonWidgetState extends State<PulsingNextButtonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PulsingNextButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse ||
        (oldWidget.onPressed == null) != (widget.onPressed == null)) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final highlighted = widget.pulse && widget.onPressed != null;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (highlighted) {
      if (disableAnimations) {
        _controller
          ..stop()
          ..value = 1.0;
      } else if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller
        ..stop()
        ..value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primaryFixed,
        foregroundColor: AppColors.onPrimaryFixed,
        // Material 3 disabled state — neutral tint on `onSurface` rather
        // than a faded primary. Faded primary (0.38 alpha) still read as
        // a slightly muted "GO" green at glance, so users tapped the
        // disabled NEXT TARGET / NEXT ROUND button expecting it to fire
        // (#261). Neutral tint clearly communicates "not actionable yet".
        disabledBackgroundColor:
            cs.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor:
            cs.onSurface.withValues(alpha: AppTheme.opacityDisabled),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      onPressed: widget.onPressed,
      icon: const Icon(Icons.arrow_forward, semanticLabel: ''),
      label: Text(widget.label),
    );

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final t = _pulseAnim.value;
        if (t == 0.0) return child!;
        final scale = 1.0 + (0.04 * t);
        final glowOpacity = 0.20 + (0.55 * t);
        final glowBlur = 10.0 + (22.0 * t);
        final glowSpread = 0.5 + (3.0 * t);
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: cs.primaryFixed.withValues(alpha: glowOpacity),
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: button,
    );
  }
}
