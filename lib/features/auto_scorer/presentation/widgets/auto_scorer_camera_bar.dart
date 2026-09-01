import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_alert.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/contribution_counter_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The rare camera actions, behind one labelled menu (#761).
enum CameraBarAction { reAim, removeDarts, stop }

/// The control row under the in-game camera preview while detection runs.
///
/// Pure UI — no providers, no camera: the host owns the state and the actions,
/// which is what makes this row (unlike the rest of the camera path) testable
/// without a device.
class AutoScorerCameraBar extends StatelessWidget {
  const AutoScorerCameraBar({
    super.key,
    required this.status,
    required this.everCalibrated,
    required this.contributions,
    required this.showContributions,
    required this.onReAim,
    required this.onRemoveDarts,
    required this.onStop,
  });

  final TrackerStatus status;
  final bool everCalibrated;
  final int contributions;

  /// Whether training photos are being recorded at all. With the opt-in off
  /// nothing is ever captured, so a counter would promise something that is not
  /// happening.
  final bool showContributions;

  final VoidCallback onReAim;
  final VoidCallback onRemoveDarts;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lost = calibrationAlertOf(
            phase: status.phase, everCalibrated: everCalibrated) ==
        CalibrationAlert.lost;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AutoScorerStatusChip(
                status: status, everCalibrated: everCalibrated),
          ),
        ),
        // Only once something has actually been captured (#761): a counter
        // sitting at zero for a whole game is what a WORKING camera looks like,
        // and it reads as a broken feature. The settings tile carries the
        // running total when there is nothing to show here.
        if (showContributions && contributions > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ContributionCounter(count: contributions),
          ),
        // Re-aiming is the way OUT of a lost calibration, so it stays one tap
        // while that alert is up (#761): burying the recovery in a menu at the
        // exact moment it is needed would be worse than the icon wall this
        // replaces. Labelled, because the icon alone never said what it did.
        if (lost)
          TextButton.icon(
            onPressed: onReAim,
            icon: const Icon(Icons.center_focus_strong, size: 18),
            label: Text(l10n.autoScorerReAim),
          ),
        // Everything else is rare and lives behind one menu with words (#761).
        // Three unlabelled icons — a broom for "I pulled the darts" worst of
        // all — could not be guessed, and they crowded a row whose status text
        // was already being clipped.
        PopupMenuButton<CameraBarAction>(
          tooltip: l10n.autoScorerCameraActions,
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case CameraBarAction.reAim:
                onReAim();
              case CameraBarAction.removeDarts:
                onRemoveDarts();
              case CameraBarAction.stop:
                onStop();
            }
          },
          itemBuilder: (_) => [
            _item(CameraBarAction.reAim, Icons.center_focus_strong,
                l10n.autoScorerReAim),
            _item(CameraBarAction.removeDarts, Icons.cleaning_services,
                l10n.autoScorerRemoveDarts),
            _item(CameraBarAction.stop, Icons.stop_circle_outlined,
                l10n.autoScorerStop),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<CameraBarAction> _item(
          CameraBarAction value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
        ),
      );
}
