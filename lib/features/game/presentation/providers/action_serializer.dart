import 'dart:async';

/// FIFO serializer for async actions on a single notifier.
///
/// Each call to [run] queues behind any in-flight or pending calls and
/// resolves in submission order. Used by the active-game notifiers to
/// serialize sequence-allocating operations (`processDart`, `advanceTurn`,
/// `undoDart`, etc.) so two rapid taps cannot both read the same
/// `getLatestSequence` value and collide on insert.
///
/// Errors thrown by an action are rethrown to that caller only — the queue
/// continues so a transient failure does not poison subsequent actions.
class ActionSerializer {
  Future<void>? _tail;

  Future<T> run<T>(Future<T> Function() body) async {
    final prev = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    try {
      if (prev != null) {
        try {
          await prev;
        } catch (_) {
          // Prior action's error already surfaced to its own caller.
        }
      }
      return await body();
    } finally {
      completer.complete();
      if (identical(_tail, completer.future)) _tail = null;
    }
  }
}
