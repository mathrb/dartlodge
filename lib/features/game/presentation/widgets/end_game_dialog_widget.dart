import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/app_dialog_widget.dart';

class EndGameDialogWidget extends StatelessWidget {
  const EndGameDialogWidget({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppDialogWidget(
      title: l10n.gameEndGameTitle,
      content: l10n.gameEndGameBody,
      actions: [
        DialogAction(
          label: l10n.commonCancel,
          onPressed: onCancel,
          autoClose: false,
        ),
        DialogAction(
          label: l10n.gameMenuEndGame,
          onPressed: onConfirm,
          isDestructive: true,
          autoClose: false,
        ),
      ],
    );
  }
}
