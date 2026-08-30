import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// How long the highlight pulse runs when the count goes up (#742, design S2.4).
///
/// Long enough to be noticed at the oche out of the corner of an eye, short
/// enough to be over before the player throws again. Deliberately NOT a
/// SnackBar: manual entry happens up to three times per turn, and three
/// snackbars per turn would cover the board and fight the existing
/// correction/export ones.
const Duration kContributionPulseDuration = Duration(milliseconds: 600);

/// Compact "training photos captured this game" counter for the in-game camera
/// bar row (#742, design S2.3).
///
/// The capture on manual entry (#537) is otherwise completely silent, so the
/// player has no reason to believe that playing with an unrecognised board is
/// worth anything. This is the acknowledgement: it counts, and it pulses as it
/// increments.
///
/// Pure UI — the caller owns the count (the session counts its own successful
/// persists) and decides whether to show it at all: it must be absent when
/// recording is off.
class ContributionCounter extends StatefulWidget {
  const ContributionCounter({super.key, required this.count});

  /// Frames persisted so far in this game — it accumulates across camera
  /// stop/start, so stopping the camera never appears to undo a contribution.
  final int count;

  @override
  State<ContributionCounter> createState() => _ContributionCounterState();
}

class _ContributionCounterState extends State<ContributionCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: kContributionPulseDuration,
  );

  @override
  void didUpdateWidget(covariant ContributionCounter old) {
    super.didUpdateWidget(old);
    // Only a rise is worth acknowledging — a reset (new camera session) is not
    // a contribution.
    if (widget.count > old.count) {
      _pulse
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final highlight = AppTheme.success(context);
    return Semantics(
      // One node reading the whole thing: the bare number inside would
      // otherwise be announced on its own, without saying what it counts.
      container: true,
      excludeSemantics: true,
      label: l10n.autoScorerContributionsSemantics(widget.count),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, __) {
          // One triangular ramp: out to the highlight and back. `t` is 0 at
          // rest, so the counter sits in the ordinary chrome colours between
          // captures.
          final t = _pulse.value <= 0.5
              ? _pulse.value * 2
              : (1 - _pulse.value) * 2;
          final fg = Color.lerp(scheme.onSurfaceVariant, highlight, t)!;
          return Transform.scale(
            scale: 1 + 0.12 * t,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color.lerp(
                    Colors.transparent, highlight.withValues(alpha: 0.16), t),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera_back_outlined, size: 16, color: fg),
                  const SizedBox(width: 4),
                  Text(
                    StatFormatter.fmtInt(widget.count),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
