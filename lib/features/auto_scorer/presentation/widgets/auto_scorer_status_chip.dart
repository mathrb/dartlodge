import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Compact status chip for assist mode (#382 §5.2): keeps the scoreboard
/// primary while surfacing "2 darts detected" / "camera moved" / "turn full".
/// The phase→text/icon mapping is a pure static ([describe]) so it is testable
/// without pumping a widget.
class AutoScorerStatusChip extends StatelessWidget {
  final TrackerStatus status;

  const AutoScorerStatusChip({super.key, required this.status});

  /// Pure presentation mapping for the chip. Returns the user-facing (localized)
  /// label and an icon for the given [status].
  static ({String label, IconData icon}) describe(
      AppLocalizations l10n, TrackerStatus status) {
    switch (status.phase) {
      case TrackerPhase.noCalibration:
        return (label: l10n.autoScorerStatusAim, icon: Icons.visibility_off);
      case TrackerPhase.needsCalibration:
        return (
          label: l10n.autoScorerStatusNeedsCal,
          icon: Icons.crop_free
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
    final info = describe(AppLocalizations.of(context), status);
    final isAlert = status.phase == TrackerPhase.turnFull ||
        status.phase == TrackerPhase.cameraMoved ||
        status.phase == TrackerPhase.needsCalibration;
    final fg = isAlert ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    final bg = isAlert ? scheme.errorContainer : scheme.secondaryContainer;
    return Chip(
      backgroundColor: bg,
      avatar: Icon(info.icon, size: 20, color: fg),
      // titleMedium (#480): with the camera collapsed to a vignette, this chip
      // is the at-distance status/alert line — one typographic step up from
      // the default chip label so its colour + text read from the oche.
      label: Text(info.label,
          style: AppTextStyles.titleMedium.copyWith(color: fg)),
    );
  }
}
