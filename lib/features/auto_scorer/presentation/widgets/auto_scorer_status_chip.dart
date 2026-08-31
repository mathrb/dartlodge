import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_alert.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Compact status chip for assist mode (#382 §5.2): keeps the scoreboard
/// primary while surfacing "2 darts detected" / "camera moved" / "turn full".
/// The phase→text/icon mapping is a pure static ([describe]) so it is testable
/// without pumping a widget.
class AutoScorerStatusChip extends StatelessWidget {
  final TrackerStatus status;

  /// Whether the board has been calibrated at least once in this camera
  /// session. It splits the sustained "no calibration" phase in two (#741):
  /// false → learning mode (calm), true → the board was lost (red alert). See
  /// [calibrationAlertOf].
  final bool everCalibrated;

  const AutoScorerStatusChip({
    super.key,
    required this.status,
    required this.everCalibrated,
  });

  /// Pure presentation mapping for the chip. Returns the user-facing (localized)
  /// label and an icon for the given [status], read through [everCalibrated]
  /// (see the class doc).
  static ({String label, IconData icon}) describe(
      AppLocalizations l10n, TrackerStatus status,
      {required bool everCalibrated}) {
    switch (status.phase) {
      case TrackerPhase.noCalibration:
        return (label: l10n.autoScorerStatusAim, icon: Icons.visibility_off);
      case TrackerPhase.needsCalibration:
        // Never calibrated = the player is scoring by hand on purpose; saying
        // "camera needs calibration" in red for a whole game reads as a fault.
        return everCalibrated
            ? (label: l10n.autoScorerStatusNeedsCal, icon: Icons.crop_free)
            : (
                label: l10n.autoScorerStatusLearningMode,
                icon: Icons.edit_note_outlined
              );
      case TrackerPhase.idle:
        return (label: l10n.autoScorerStatusReady, icon: Icons.center_focus_weak);
      case TrackerPhase.tracking:
        return (
          label: l10n.autoScorerStatusDetected(status.dartsOnBoard),
          icon: Icons.center_focus_strong
        );
      case TrackerPhase.turnFull:
        return (label: l10n.autoScorerStatusTurnFull, icon: Icons.do_not_disturb_on);
      case TrackerPhase.cameraMoved:
        return (label: l10n.autoScorerStatusCameraMoved, icon: Icons.screen_rotation);
      case TrackerPhase.rebaselined:
        return (label: l10n.autoScorerStatusBoardCleared, icon: Icons.cleaning_services);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = describe(AppLocalizations.of(context), status,
        everCalibrated: everCalibrated);
    // Learning mode is a valid way to play, so it never renders errorContainer
    // (#741): only a calibration that was there and went away alarms.
    final isAlert = status.phase == TrackerPhase.turnFull ||
        status.phase == TrackerPhase.cameraMoved ||
        calibrationAlertOf(
                phase: status.phase, everCalibrated: everCalibrated) ==
            CalibrationAlert.lost;
    final fg = isAlert ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    final bg = isAlert ? scheme.errorContainer : scheme.secondaryContainer;
    return Chip(
      backgroundColor: bg,
      avatar: Icon(info.icon, size: 20, color: fg),
      // titleMedium (#480): with the camera collapsed to a vignette, this chip
      // is the at-distance status/alert line — one typographic step up from
      // the default chip label so its colour + text read from the oche.
      //
      // FittedBox(scaleDown) because the chip shares its row with the
      // contribution counter and the camera actions: at titleMedium the
      // longest labels ("Camera moet gekalibreerd worden", nl) outgrow the
      // width left to them and used to be CLIPPED MID-WORD, with no ellipsis
      // (#764). Shrinking keeps every word — an ellipsis would drop the
      // actionable half of "Turn full — advance". Same idiom as the ATC
      // summary headline (#261); labels that fit render at full size.
      label: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(info.label,
            maxLines: 1,
            style: AppTextStyles.titleMedium.copyWith(color: fg)),
      ),
    );
  }
}
