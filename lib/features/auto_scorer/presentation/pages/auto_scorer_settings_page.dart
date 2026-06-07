import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/diagnostics_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/setup_tips_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
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
    final calConf = ref.watch(autoScorerCalConfidenceProvider);
    final dartConf = ref.watch(autoScorerDartConfidenceProvider);

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
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Camera setup tips'),
            subtitle: const Text('How to frame the board for best results.'),
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => const AutoScorerSetupTipsView()));
              // Honour "don't show again" when reviewed here too (null = back,
              // leaves the pref untouched).
              if (result != null) {
                ref
                    .read(autoScorerSetupTipsSeenProvider.notifier)
                    .setSeen(result);
              }
            },
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
          // Detection thresholds (#377 §3). The model's recall is measured at a
          // near-zero eval threshold, so a lower operating threshold recovers
          // borderline cal points / darts; expose both so they can be tuned
          // against the HUD's per-cal confidence readout.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Detection thresholds',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _ConfidenceSlider(
            icon: Icons.crop_free,
            label: 'Calibration confidence',
            value: calConf.value ?? kDefaultConfidence,
            enabled: !calConf.isLoading,
            onChanged: (v) =>
                ref.read(autoScorerCalConfidenceProvider.notifier).set(v),
          ),
          _ConfidenceSlider(
            icon: Icons.my_location,
            label: 'Dart confidence',
            value: dartConf.value ?? kDefaultConfidence,
            enabled: !dartConf.isLoading,
            onChanged: (v) =>
                ref.read(autoScorerDartConfidenceProvider.notifier).set(v),
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
            title: const Text('Skip preprocessing'),
            subtitle: const Text(
                'Send raw frames straight to the model (native resize) instead '
                'of our 800×800 letterbox. Much faster, but a different input '
                'than the model trained on. Automatic training capture pauses '
                'while on (the manual capture button still works).'),
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
    final count = captures.length;
    await shareCaptureZip(await store.buildExportZip());
    // The export zips every stored capture, so re-exporting re-includes ones
    // already shared. Offer to clear them after the share sheet closes so they
    // don't pile up / re-export. Prompt (not auto-clear) because the share
    // result isn't reliable on Android — a cancelled share shouldn't wipe data.
    if (!context.mounted) return;
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear exported frames?'),
        content: Text(
            'Exported $count frame${count == 1 ? '' : 's'}. Clear all captured '
            'frames from this device so they are not exported again?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (clear == true) {
      await store.clear();
      messenger.showSnackBar(SnackBar(
          content: Text('Cleared $count exported frame${count == 1 ? '' : 's'}')));
    }
  }
}

/// A 0.05–0.90 confidence slider that keeps the thumb responsive during a drag
/// (local state) and persists only on release (`onChangeEnd`), so we don't write
/// SharedPreferences on every pixel of movement.
class _ConfidenceSlider extends StatefulWidget {
  const _ConfidenceSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_ConfidenceSlider> createState() => _ConfidenceSliderState();
}

class _ConfidenceSliderState extends State<_ConfidenceSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.value;
    return ListTile(
      leading: Icon(widget.icon),
      title: Text('${widget.label}: ${StatFormatter.fmtDouble(value, decimals: 2)}'),
      subtitle: Slider(
        value: value.clamp(0.05, 0.9),
        min: 0.05,
        max: 0.9,
        divisions: 17, // 0.05 steps
        label: StatFormatter.fmtDouble(value, decimals: 2),
        onChanged: widget.enabled
            ? (v) => setState(() => _dragValue = v)
            : null,
        onChangeEnd: widget.enabled
            ? (v) {
                setState(() => _dragValue = null);
                widget.onChanged(v);
              }
            : null,
      ),
    );
  }
}
