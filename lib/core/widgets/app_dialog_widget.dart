import 'package:flutter/material.dart';

class DialogAction {
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.autoClose = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  /// When true, [Navigator.pop] is called before invoking [onPressed].
  final bool autoClose;
}

class AppDialogWidget extends StatelessWidget {
  const AppDialogWidget({
    required this.title,
    required this.actions,
    this.content,
    super.key,
  });

  final String title;
  final String? content;
  final List<DialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: actions.map((action) {
        void handleTap() {
          if (action.autoClose) Navigator.of(context).pop();
          action.onPressed();
        }

        if (action.isDestructive) {
          return FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: handleTap,
            child: Text(action.label),
          );
        }
        return TextButton(
          onPressed: handleTap,
          child: Text(action.label),
        );
      }).toList(),
    );
  }
}
