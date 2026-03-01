import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text('Leg $legNumber won by $winnerName'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNextLeg();
          },
          child: const Text('Next Leg'),
        ),
      ],
    );
  }
}
