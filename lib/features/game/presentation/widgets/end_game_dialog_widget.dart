import 'package:flutter/material.dart';

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
    return AppDialogWidget(
      title: 'End Game?',
      content: 'The current game will be abandoned.',
      actions: [
        DialogAction(
          label: 'Cancel',
          onPressed: onCancel,
          autoClose: false,
        ),
        DialogAction(
          label: 'End Game',
          onPressed: onConfirm,
          isDestructive: true,
          autoClose: false,
        ),
      ],
    );
  }
}
