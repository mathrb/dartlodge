import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/auto_advance_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
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
class AutoScorerSettingsPage extends ConsumerStatefulWidget {
  const AutoScorerSettingsPage({super.key});

  @override
  ConsumerState<AutoScorerSettingsPage> createState() =>
      _AutoScorerSettingsPageState();
}

class _AutoScorerSettingsPageState
    extends ConsumerState<AutoScorerSettingsPage> {
  // Inline export progress (#468). While exporting, the Export tile shows a
  // determinate bar (fraction of capture files zipped) and disables its tap.
  bool _exporting = false;
  double _exportProgress = 0;

  @override
  Widget build(BuildContext context) {
    final useAuto = ref.watch(autoScoringEnabledProvider);
    final autoAdvance = ref.watch(autoAdvanceOnClearEnabledProvider);
    final collect = ref.watch(dataCollectionEnabledProvider);
    final captureMode = ref.watch(captureModeSettingProvider);
    final collectOn = collect.value ?? false;
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
          SwitchListTile(
            secondary: const Icon(Icons.skip_next),
            title: const Text('Auto-advance turn when board is cleared'),
            subtitle: const Text(
                'When all darts are removed, advance to the next player '
                'automatically instead of pressing NEXT.'),
            value: autoAdvance.value ?? false,
            onChanged: autoAdvance.isLoading
                ? null
                : (v) => ref
                    .read(autoAdvanceOnClearEnabledProvider.notifier)
                    .setEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Camera setup tips'),
            subtitle: const Text('How to frame the board for best results.'),
            // Review-only: opened just to re-read the tips, so the "don't show
            // again" checkbox and "Continue to camera" button are hidden and we
            // never touch the "seen" pref. The one-time prompt + dismissal live
            // on the game-flow path (board overlay's _start()).
            onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) =>
                    const AutoScorerSetupTipsView(reviewOnly: true))),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dataset),
            title: const Text('Collect training data'),
            subtitle: const Text(
                'Store board photos + corrections to improve detection. Stays '
                'on this device until you export.'),
            value: collectOn,
            onChanged: collect.isLoading
                ? null
                : (v) => ref
                    .read(dataCollectionEnabledProvider.notifier)
                    .setEnabled(v),
          ),
          // Capture mode (#457): "All" saves every detected dart; "Mistakes
          // only" saves just the frames you correct (the model's errors), so the
          // dataset isn't flooded with easy/correct examples. Only relevant —
          // and only enabled — while data collection is on.
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('What to capture'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<CaptureMode>(
                segments: const [
                  ButtonSegment(value: CaptureMode.all, label: Text('All')),
                  ButtonSegment(
                      value: CaptureMode.partial, label: Text('Mistakes only')),
                ],
                selected: {captureMode.value ?? CaptureMode.all},
                onSelectionChanged: (!collectOn || captureMode.isLoading)
                    ? null
                    : (selection) => ref
                        .read(captureModeSettingProvider.notifier)
                        .setMode(selection.first),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export training data'),
            subtitle: _exporting
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: _exportProgress),
                        const SizedBox(height: 4),
                        Text(
                            'Building zip… ${StatFormatter.fmtPct(_exportProgress, decimals: 0)}'),
                      ],
                    ),
                  )
                : const Text('Share a zip of captured frames.'),
            onTap: _exporting ? null : () => _export(context),
          ),
          const Divider(),
          // Detection thresholds (#377 §3). The model's recall is measured at a
          // near-zero eval threshold, so a lower operating threshold recovers
          // borderline cal points / darts; expose both so they can be tuned
          // against the calibration overlay's per-cal confidence readout.
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
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
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
    final dest = await reserveExportZipPath();
    setState(() {
      _exporting = true;
      _exportProgress = 0;
    });
    try {
      await store.writeExportZip(dest, onProgress: (p) {
        if (mounted) setState(() => _exportProgress = p);
      });
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
    await shareCaptureZipFile(dest);
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
