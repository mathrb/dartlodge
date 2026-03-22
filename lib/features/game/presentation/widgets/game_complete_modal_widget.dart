import 'package:flutter/material.dart';

import '../../../../core/widgets/app_dialog_widget.dart';

class GameCompleteModalWidget extends StatelessWidget {
  const GameCompleteModalWidget({
    required this.winnerName,
    required this.onNewGame,
    required this.onViewStats,
    super.key,
  });

  final String winnerName;
  final VoidCallback onNewGame;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context) {
    return AppDialogWidget(
      title: '$winnerName wins!',
      actions: [
        DialogAction(
          label: 'New Game',
          onPressed: onNewGame,
          autoClose: true,
        ),
        DialogAction(
          label: 'View Stats',
          onPressed: onViewStats,
          autoClose: true,
        ),
      ],
    );
  }
}
