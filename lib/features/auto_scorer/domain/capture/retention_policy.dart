import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';

/// Lightweight metadata about one stored capture, used by [RetentionPolicy] to
/// decide what to prune without loading frame bytes.
class CaptureMeta {
  final String gameId;
  final CaptureHandle handle;
  final int sizeBytes;
  final DateTime timestamp;
  final bool wasCorrected;

  const CaptureMeta({
    required this.gameId,
    required this.handle,
    required this.sizeBytes,
    required this.timestamp,
    required this.wasCorrected,
  });
}

/// Caps total capture storage (#381 §6, a tuning knob per #377 §11).
///
/// Corrected captures are the most valuable training data, so they are pruned
/// last: the policy first drops un-corrected captures oldest-first, and only if
/// still over the cap falls back to dropping corrected ones oldest-first. The
/// `local-first privacy` story means we never silently hoard unbounded frames.
class RetentionPolicy {
  final int maxBytes;

  const RetentionPolicy({required this.maxBytes});

  /// Given all stored captures, returns the subset to delete to bring the total
  /// under [maxBytes]. Returns an empty list when already within budget.
  List<CaptureMeta> selectForPruning(List<CaptureMeta> all) {
    var total = all.fold<int>(0, (sum, c) => sum + c.sizeBytes);
    if (total <= maxBytes) return const [];

    int byOldest(CaptureMeta a, CaptureMeta b) =>
        a.timestamp.compareTo(b.timestamp);
    final unCorrected = all.where((c) => !c.wasCorrected).toList()..sort(byOldest);
    final corrected = all.where((c) => c.wasCorrected).toList()..sort(byOldest);

    final toDelete = <CaptureMeta>[];
    for (final c in [...unCorrected, ...corrected]) {
      if (total <= maxBytes) break;
      toDelete.add(c);
      total -= c.sizeBytes;
    }
    return toDelete;
  }
}
