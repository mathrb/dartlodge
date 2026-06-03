import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/diagnostics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Web-guarded share helper (no-op stub on web).
import 'package:dart_lodge/features/auto_scorer/data/capture/capture_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/capture/capture_io.dart';

/// Auto-scoring settings (#382 §5.1 + #381 §6): the two independent opt-ins
/// ("use auto-scoring" and "collect training data") plus the training-data
/// export. Lives in the auto_scorer feature; the main Settings page links here
/// by route, so neither feature imports the other.
class AutoScorerSettingsPage extends ConsumerWidget {
  const AutoScorerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAuto = ref.watch(autoScoringEnabledProvider);
    final collect = ref.watch(dataCollectionEnabledProvider);
    final timingHud = ref.watch(autoScorerTimingHudEnabledProvider);
    final skipPreprocess = ref.watch(autoScorerSkipPreprocessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-scoring')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.center_focus_strong),
            title: const Text('Use auto-scoring'),
            subtitle: const Text(
                'Camera-assisted dart entry on X01 and Cricket (beta).'),
            value: useAuto.value ?? false,
            onChanged: useAuto.isLoading
                ? null
                : (v) =>
                    ref.read(autoScoringEnabledProvider.notifier).setEnabled(v),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dataset),
            title: const Text('Collect training data'),
            subtitle: const Text(
                'Store board photos + corrections to improve detection. Stays '
                'on this device until you export.'),
            value: collect.value ?? false,
            onChanged: collect.isLoading
                ? null
                : (v) => ref
                    .read(dataCollectionEnabledProvider.notifier)
                    .setEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export training data'),
            subtitle: const Text('Share a zip of captured frames.'),
            onTap: () => _export(context, ref),
          ),
          const Divider(),
          // Developer diagnostics for the lag investigation (#377 §3). Both off
          // by default; they only affect an active auto-scoring session.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Diagnostics',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed),
            title: const Text('Show timing HUD'),
            subtitle: const Text(
                'Overlay per-frame capture / detect / track timings while '
                'auto-scoring runs.'),
            value: timingHud.value ?? false,
            onChanged: timingHud.isLoading
                ? null
                : (v) => ref
                    .read(autoScorerTimingHudEnabledProvider.notifier)
                    .setEnabled(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.compare_arrows),
            title: const Text('Skip preprocessing (A/B)'),
            subtitle: const Text(
                'Send raw frames to the model instead of our 800×800 resize, to '
                'measure preprocess cost. Perf test only — training capture is '
                'paused while this is on.'),
            value: skipPreprocess.value ?? false,
            onChanged: skipPreprocess.isLoading
                ? null
                : (v) => ref
                    .read(autoScorerSkipPreprocessProvider.notifier)
                    .setEnabled(v),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final store = await ref.read(captureStoreProvider.future);
    if (!store.isSupported) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Export is not available here.')));
      return;
    }
    final captures = await store.list();
    if (captures.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No captured frames to export yet.')));
      return;
    }
    await shareCaptureZip(await store.buildExportZip());
  }
}
