import 'dart:async';

import 'package:flutter/material.dart';

class BustOverlayWidget extends StatefulWidget {
  const BustOverlayWidget({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  State<BustOverlayWidget> createState() => _BustOverlayWidgetState();
}

class _BustOverlayWidgetState extends State<BustOverlayWidget> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.red.withOpacity(0.6),
        child: const Center(
          child: Text(
            'BUST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
