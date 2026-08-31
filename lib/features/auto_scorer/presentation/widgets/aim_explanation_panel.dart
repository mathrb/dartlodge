import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The explanation the aim view shows when the board is never recognised
/// (#743, design S2.1 + S2.5).
///
/// Says what is happening, what usually causes it, and that the player can just
/// play — by hand, still usefully. It replaces the hint region **in place**: it
/// is not a dialog and not a pushed route, because the player is holding a
/// phone at a board and an interruption that must be dismissed before
/// re-aiming would be worse than the silence it fixes.
///
/// Pure UI: the caller owns when it appears ([shouldExplainAim]), what the
/// actions do, and whether recording is on. Sits over the live camera, so it
/// paints its own opaque surface.
class AimExplanationPanel extends StatelessWidget {
  const AimExplanationPanel({
    super.key,
    required this.recordingOn,
    required this.onPlayAnyway,
    required this.onKeepAiming,
    required this.onEnableRecording,
  });

  /// Whether photos are actually being kept. With it off the panel offers to
  /// turn it on — this is the one moment where the trade-off is self-evident,
  /// and the only place we ask.
  final bool recordingOn;

  /// Primary action: stop aiming and play, scoring by hand.
  final VoidCallback onPlayAnyway;

  /// Secondary action: put the panel away and keep trying to frame the board.
  final VoidCallback onKeepAiming;

  /// Turn recording on from here. Declining must still let the player proceed,
  /// so this is never a precondition of [onPlayAnyway].
  final VoidCallback onEnableRecording;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ConstrainedBox(
      // The camera fills the screen behind this, and the aim controls (zoom,
      // capture, Cancel/confirm) are stacked at the bottom of the same screen
      // — roughly a quarter of it. Cap the panel below the remaining room so
      // the two can never meet on a short screen, and scroll the prose inside
      // when it needs more (large text scales, small phones).
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      ),
      child: Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only the prose scrolls. The two actions stay pinned below it,
              // so a small screen (or a large text scale) can never hide the
              // way out of a panel that is itself about being stuck.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.autoScorerExplainTitle,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(l10n.autoScorerExplainCauses,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Text(l10n.autoScorerExplainLoop,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      // The recording state is part of the honest story: with
                      // it off, playing by hand helps nobody, so say so and
                      // offer the switch.
                      if (recordingOn)
                        Text(l10n.autoScorerExplainRecordingOn,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant))
                      else ...[
                        Text(l10n.autoScorerExplainRecordingOff,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onEnableRecording,
                            icon:
                                const Icon(Icons.fiber_manual_record_outlined),
                            label:
                                Text(l10n.autoScorerExplainEnableRecording),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onKeepAiming,
                    child: Text(l10n.autoScorerExplainKeepAiming),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onPlayAnyway,
                    child: Text(l10n.autoScorerExplainPlayAnyway),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
