import 'package:flutter/material.dart';

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
    return AppDialogWidget(
      title: 'Leg $legNumber won by $winnerName',
      actions: [
        DialogAction(
          label: 'Next Leg',
          onPressed: onNextLeg,
          autoClose: true,
        ),
      ],
    );
  }
}
