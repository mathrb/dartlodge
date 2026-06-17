import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/app_dialog_widget.dart';

class LegCompleteModalWidget extends StatelessWidget {
  const LegCompleteModalWidget({
    required this.winnerName,
    required this.legNumber,
    required this.onNextLeg,
    super.key,
  });

  final String winnerName;
  final int legNumber;
  final VoidCallback onNextLeg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppDialogWidget(
      title: l10n.gameLegWonBy(legNumber, winnerName),
      actions: [
        DialogAction(
          label: l10n.gameNextLeg,
          onPressed: onNextLeg,
          autoClose: true,
        ),
      ],
    );
  }
}
