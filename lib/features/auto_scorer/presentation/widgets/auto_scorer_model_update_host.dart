import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global, always-mounted host that kicks off the one-time launch check for an
/// out-of-band auto-scorer model update (#715), gated on the master
/// "Use auto-scoring" switch. The download itself gates on an unmetered
/// connection inside the service, and any newly staged model only takes effect
/// at the next scoring session — never mid-game.
///
/// Mounted via `MaterialApp.router`'s `builder` (below `ProviderScope`), mirroring
/// [AchievementNotificationHost]. Web/iOS are no-ops (the service reports
/// `isSupported == false`). Fires at most once per app launch.
class AutoScorerModelUpdateHost extends ConsumerStatefulWidget {
  const AutoScorerModelUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoScorerModelUpdateHost> createState() =>
      _AutoScorerModelUpdateHostState();
}

class _AutoScorerModelUpdateHostState
    extends ConsumerState<AutoScorerModelUpdateHost> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Defer past first frame so the launch check never competes with startup
    // rendering; it is best-effort and silent.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheck());
  }

  Future<void> _maybeCheck() async {
    if (_checked) return;
    final enabled = await ref.read(autoScoringEnabledProvider.future);
    if (!mounted || _checked || !enabled) return;
    _checked = true;
    // Fire-and-forget: checkNow is best-effort and never throws.
    await ref.read(modelUpdateControllerProvider.notifier).checkNow();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
