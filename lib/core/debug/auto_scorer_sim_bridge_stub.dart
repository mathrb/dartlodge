import 'package:flutter/widgets.dart';

/// Non-web no-op for the Playwright sim bridge (see `auto_scorer_sim_bridge.dart`).
/// The JS hook only exists on web; on every other platform this is a transparent
/// pass-through so the gated `main.dart` wrap compiles everywhere.
class AutoScorerSimBridge extends StatelessWidget {
  const AutoScorerSimBridge({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
