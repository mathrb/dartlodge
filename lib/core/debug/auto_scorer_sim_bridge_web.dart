import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auto_scorer_providers.dart';

/// Web implementation of the Playwright sim bridge (see
/// `auto_scorer_sim_bridge.dart`). Mounted only when
/// `--dart-define=AUTOSCORER_SIM=true`. Registers `window.dartlodgeSim` with
/// hooks that inject auto-scorer events through the live [DartInputSink] —
/// exactly where the native detector emits (`sink.submitDart(...)`) — so a
/// Playwright run can drive the camera-first UI without a camera.
///
/// It mocks *post-detection*: it does NOT exercise the native tracker / 3-dart
/// cap / board-clear detection (those are Android-only and absent on web).
class AutoScorerSimBridge extends ConsumerStatefulWidget {
  const AutoScorerSimBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoScorerSimBridge> createState() =>
      _AutoScorerSimBridgeState();
}

class _AutoScorerSimBridgeState extends ConsumerState<AutoScorerSimBridge> {
  static const _globalKey = 'dartlodgeSim';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _register();
    });
  }

  void _register() {
    final api = JSObject();
    // Emit one detected dart into the active game (no-op if no board is open).
    api.setProperty(
      'emit'.toJS,
      ((JSString segment) => _afterFrame(() {
            ref.read(activeDartInputSinkProvider)?.submitDart(segment.toDart);
          })).toJS,
    );
    // Advance the turn (the board-clear path; no UI trigger exists otherwise).
    api.setProperty(
      'advance'.toJS,
      (() => _afterFrame(() {
            ref.read(activeDartInputSinkProvider)?.advanceTurn();
          })).toJS,
    );
    // Turn auto-scoring on so boards switch to the camera-first layout.
    api.setProperty(
      'enableAutoScoring'.toJS,
      (() => _afterFrame(() {
            ref.read(autoScoringEnabledProvider.notifier).setEnabled(true);
          })).toJS,
    );
    globalContext.setProperty(_globalKey.toJS, api);
  }

  /// Runs [action], then resolves the returned JS promise at the end of the next
  /// frame so a Playwright `await` lands after the resulting rebuild has painted.
  /// (Assertions still poll, so this only reduces flakiness.)
  JSPromise<JSAny?> _afterFrame(void Function() action) {
    final completer = Completer<JSAny?>();
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
    });
    return completer.future.toJS;
  }

  @override
  void dispose() {
    globalContext.setProperty(_globalKey.toJS, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
