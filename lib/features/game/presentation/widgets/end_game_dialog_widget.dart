import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('End Game?', style: AppTextStyles.headingSmall),
      content: Text(
        'The current game will be abandoned.',
        style: tt.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: cs.onSurface)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          onPressed: onConfirm,
          child: const Text('End Game'),
        ),
      ],
    );
  }
}
