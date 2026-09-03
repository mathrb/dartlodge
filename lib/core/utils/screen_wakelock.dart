import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while a board is on screen, without ever letting a
/// platform refusal escape as an unhandled error.
///
/// Board pages fire these without awaiting (from `initState` / `dispose`), so a
/// rejected `WakelockPlus.toggle` becomes an uncaught async error and lands in
/// Sentry as a *fatal* crash. That is exactly what happens on web: the plugin's
/// `no_sleep.js` rejects with a bare `String` built as `err.name + ', ' +
/// err.message`, and Mobile Safari refuses the Screen Wake Lock API with
/// `NotAllowedError, Permission was denied` (Sentry MY-DARTS-P) — e.g. in Low
/// Power Mode or when the document isn't fully active.
///
/// The wakelock is a convenience, never a correctness requirement: when the
/// platform says no, the board carries on and the screen simply dims as usual.
///
/// Boards must go through this class — never call `WakelockPlus` directly.
abstract final class ScreenWakelock {
  /// The platform call, swappable in tests (the plugin exposes no fake).
  @visibleForTesting
  static Future<void> Function({required bool enable}) platformToggle =
      WakelockPlus.toggle;

  /// Requests that the screen stays on. Never throws, never needs awaiting.
  static void enable() => _toggle(enable: true);

  /// Releases the request. Never throws, never needs awaiting.
  static void disable() => _toggle(enable: false);

  static void _toggle({required bool enable}) {
    unawaited(platformToggle(enable: enable).catchError((Object _) {}));
  }
}
