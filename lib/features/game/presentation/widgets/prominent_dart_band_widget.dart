import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
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
      child: _ContributionFlash(
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
      ),
    );
  }
}

/// How long the band acknowledges a stored training frame (#762).
///
/// Longer than the camera bar's own pulse: this one has to be caught by a
/// player who has already looked back up at the board, and it is still over
/// well before the next dart lands.
const Duration kContributionBandFlashDuration = Duration(milliseconds: 900);

/// Acknowledges a stored training frame across the WHOLE band (#762).
///
/// When the board is not recognised, entering a dart by hand stores a labelled
/// training photo — the thing that makes an unrecognised game worth playing —
/// and until now the only sign was a small counter at the other end of the
/// screen. The acknowledgement belongs at the gesture: the band the player just
/// tapped.
///
/// Deliberately the whole band and not the tapped slot: the capture is written
/// asynchronously and can land after the player has entered the NEXT dart, so
/// pointing at a slot would regularly point at the wrong one.
///
/// The tick comes from `core/` ([TrainingCaptureSignal]) — the game feature
/// never reaches into the auto-scorer — and never fires with recording off or
/// on web, so this is inert there.
class _ContributionFlash extends ConsumerStatefulWidget {
  const _ContributionFlash({required this.child});

  final Widget child;

  @override
  ConsumerState<_ContributionFlash> createState() => _ContributionFlashState();
}

class _ContributionFlashState extends ConsumerState<_ContributionFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: kContributionBandFlashDuration,
  );

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A rise only: the signal is monotonic, but a listener that fired on any
    // change would also flash on a container restart.
    ref.listen(trainingCaptureSignalProvider, (previous, next) {
      if (previous != null && next > previous) {
        _flash
          ..reset()
          ..forward();
      }
    });
    final l10n = AppLocalizations.of(context);
    final highlight = AppTheme.success(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, _) {
                // One triangular ramp out and back, so the band returns to its
                // ordinary colours on its own and nothing lingers over the
                // scores.
                final t = _flash.value <= 0.5
                    ? _flash.value * 2
                    : (1 - _flash.value) * 2;
                if (t == 0) return const SizedBox.shrink();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    color: highlight.withValues(alpha: 0.16 * t),
                    border: Border.all(
                      color: highlight.withValues(alpha: 0.9 * t),
                      // Thick on purpose: this is read from the oche, past a
                      // dart board, by someone who was not looking at the
                      // phone — the discreet version is the bug (#762).
                      width: 4,
                    ),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Opacity(
                        opacity: t,
                        child: _CapturedBadge(
                          // Spoken once per capture, because the badge only
                          // exists while the flash runs.
                          label: l10n.autoScorerCaptureSaved,
                          color: highlight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The "+1 photo" mark of the band flash: a camera and a plus one, echoing the
/// camera bar's counter, which is the number this contribution just moved.
class _CapturedBadge extends StatelessWidget {
  const _CapturedBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // One node saying what happened: the bare "+1" inside would otherwise be
      // announced on its own, without saying what it counts.
      container: true,
      excludeSemantics: true,
      liveRegion: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_back_outlined,
              size: 20,
              color: AppTheme.onSuccess(context),
            ),
            const SizedBox(width: 6),
            Text(
              '+1',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSuccess(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
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

  /// At-distance slot height (#478): sized so the segment numerals read from
  /// the oche (~2.4 m), per docs/plans/2026-06-12-camera-first-distance-
  /// readability-design.md §3.
  static const double _height = 110;

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
                // Score-numeral token (DESIGN_SYSTEM §3): segments are
                // score-like numerals; the FittedBox above only ever scales
                // DOWN long segments (MISS), it never inflates short ones.
                style: AppTextStyles.scoreMedium.copyWith(
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
                size: 40,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                semanticLabel: AppLocalizations.of(context).gameEnterDartHint,
              )
            : Icon(
                Icons.more_horiz,
                size: 32,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                semanticLabel: AppLocalizations.of(context).gameDartNotThrown,
              ),
      ),
    );
  }
}
