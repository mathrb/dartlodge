import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/app_dialog_widget.dart';

class LegCompleteModalWidget extends StatelessWidget {
  const LegCompleteModalWidget({
    required this.winnerName,
    required this.legNumber,
    required this.onNextLeg,
    this.onUndo,
    super.key,
  });

  final String winnerName;
  final int legNumber;
  final VoidCallback onNextLeg;

  /// Undoes the leg-winning dart (closing the modal first), which reopens the
  /// won leg mid-turn; the boards wire it to `undoLegWinningDart`, which also
  /// takes back any dart scored into the new leg while the modal was open.
  /// Lets a mis-tap or a camera misread on the deciding dart be corrected.
  /// The action is hidden when null.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final undo = onUndo;
    return AppDialogWidget(
      title: l10n.gameLegWonBy(legNumber, winnerName),
      actions: [
        if (undo != null)
          DialogAction(
            label: l10n.gameUndoLastDart,
            onPressed: undo,
            autoClose: true,
          ),
        DialogAction(
          label: l10n.gameNextLeg,
          onPressed: onNextLeg,
          autoClose: true,
        ),
      ],
    );
  }
}
