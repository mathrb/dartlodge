import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_count_provider.g.dart';

/// Total training frames stored on this device (#742).
///
/// This is the settings-side view of the contribution counter: the in-game one
/// counts what the running session persisted (cheap, in memory), while the
/// settings tile wants the real total across sessions — the one number that
/// answers "how much have I contributed?".
///
/// Listing the store is a directory read, so it is deliberately NOT used on the
/// capture path; the settings page invalidates this provider after clearing.
/// Zero on web, where the capture store is a stub.
@riverpod
Future<int> captureCount(Ref ref) async {
  final store = await ref.watch(captureStoreProvider.future);
  if (!store.isSupported) return 0;
  final captures = await store.list();
  return captures.length;
}
