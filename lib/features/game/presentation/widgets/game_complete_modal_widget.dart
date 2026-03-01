import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text('$winnerName wins!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNewGame();
          },
          child: const Text('New Game'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onViewStats();
          },
          child: const Text('View Stats'),
        ),
      ],
    );
  }
}
