import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_bundle.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/auto_advance_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/technical_display_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Web-guarded share helpers (no-op stubs on web).
import 'package:dart_lodge/features/auto_scorer/data/capture/capture_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/capture/capture_io.dart';

/// Auto-scoring settings (#382 §5.1 + #381 §6, streamlined in #686): the
/// "use auto-scoring" opt-in, a single "Record for debugging & training" toggle
/// (drives both the session-trace and training-photo pipelines), the unified
/// export, and the detection thresholds. Lives in the auto_scorer feature; the
/// main Settings page links here by route, so neither feature imports the other.
class AutoScorerSettingsPage extends ConsumerStatefulWidget {
  const AutoScorerSettingsPage({super.key});

  @override
  ConsumerState<AutoScorerSettingsPage> createState() =>
      _AutoScorerSettingsPageState();
}

class _AutoScorerSettingsPageState
    extends ConsumerState<AutoScorerSettingsPage> {
  // Inline export progress (#468). While exporting, the Export tile shows a
  // determinate bar (fraction of capture files + session bundles zipped) and
  // disables its tap.
  bool _exporting = false;
  double _exportProgress = 0;

  /// The single "Record" toggle (#686) drives both opt-ins together: the
  /// lightweight session trace and the board-photo training capture. Both
  /// pipelines still gate on their own provider, so this just keeps them in
  /// lockstep from one control.
  void _setRecording(bool enabled) {
    ref.read(sessionRecordingEnabledProvider.notifier).setEnabled(enabled);
    ref.read(dataCollectionEnabledProvider.notifier).setEnabled(enabled);
  }

  /// Status row for the out-of-band detection-model update channel (#715):
  /// active model version + state, with a "Check now" button. Hidden where OTA
  /// is unsupported (web/iOS) — the service reports `isSupported == false`.
  Widget _buildModelUpdateTile(AppLocalizations l10n) {
    final supported =
        ref.watch(modelUpdateServiceProvider).value?.isSupported ?? false;
    if (!supported) return const SizedBox.shrink();
    final version = ref.watch(resolvedModelProvider).value?.version ?? '…';
    final status =
        ref.watch(modelUpdateControllerProvider).value ??
            ModelUpdateStatus.upToDate;
    final downloading = status == ModelUpdateStatus.downloading;
    return ListTile(
      leading: const Icon(Icons.model_training),
      title: Text(l10n.autoScorerModelTitle),
      subtitle: Text(
        l10n.autoScorerModelStatus(version, _modelStateLabel(l10n, status)),
      ),
      trailing: downloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () =>
                  ref.read(modelUpdateControllerProvider.notifier).checkNow(),
              child: Text(l10n.autoScorerModelCheckNow),
            ),
    );
  }

  String _modelStateLabel(AppLocalizations l10n, ModelUpdateStatus status) {
    switch (status) {
      case ModelUpdateStatus.upToDate:
        return l10n.autoScorerModelUpToDate;
      case ModelUpdateStatus.downloading:
        return l10n.autoScorerModelDownloading;
      case ModelUpdateStatus.updateReady:
        return l10n.autoScorerModelUpdateReady;
    }
  }

  @override
  Widget build(BuildContext context) {
    final useAuto = ref.watch(autoScoringEnabledProvider);
    final autoAdvance = ref.watch(autoAdvanceOnClearEnabledProvider);
    final recordSessions = ref.watch(sessionRecordingEnabledProvider);
    final collect = ref.watch(dataCollectionEnabledProvider);
    final captureMode = ref.watch(captureModeSettingProvider);
    final collectOn = collect.value ?? false;
    // The single "Record" toggle (#686) reflects either underlying opt-in being
    // on, and drives both together via _setRecording.
    final recordingOn = collectOn || (recordSessions.value ?? false);
    final recordingBusy = collect.isLoading || recordSessions.isLoading;
    final calConf = ref.watch(autoScorerCalConfidenceProvider);
    final dartConf = ref.watch(autoScorerDartConfidenceProvider);
    final technical = ref.watch(autoScorerTechnicalDisplayProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoScorerTitle)),
      body: ListView(
        children: [
          // Camera setup tips first (#686): the first thing a new user should
          // read before turning auto-scoring on. Review-only — see the tile's
          // note below; the one-time prompt lives on the game-flow path.
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: Text(l10n.autoScorerSetupTipsTile),
            subtitle: Text(l10n.autoScorerSetupTipsTileSubtitle),
            onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) =>
                    const AutoScorerSetupTipsView(reviewOnly: true))),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.center_focus_strong),
            title: Text(l10n.autoScorerUseTitle),
            subtitle: Text(l10n.autoScorerUseSubtitle),
            value: useAuto.value ?? false,
            onChanged: useAuto.isLoading
                ? null
                : (v) =>
                    ref.read(autoScoringEnabledProvider.notifier).setEnabled(v),
          ),
          _buildModelUpdateTile(l10n),
          SwitchListTile(
            secondary: const Icon(Icons.skip_next),
            title: Text(l10n.autoScorerAutoAdvanceTitle),
            subtitle: Text(l10n.autoScorerAutoAdvanceSubtitle),
            value: autoAdvance.value ?? false,
            onChanged: autoAdvance.isLoading
                ? null
                : (v) => ref
                    .read(autoAdvanceOnClearEnabledProvider.notifier)
                    .setEnabled(v),
          ),
          const Divider(),
          // Single "Record (debug)" opt-in (#686): one toggle drives BOTH the
          // lightweight session trace (detections + game events, to replay a
          // scoring bug off-device) AND the board-photo training capture (to
          // improve detection). Off by default — we never silently store photos.
          SwitchListTile(
            secondary: const Icon(Icons.fiber_manual_record_outlined),
            title: Text(l10n.autoScorerRecordTitle),
            subtitle: Text(l10n.autoScorerRecordSubtitle),
            value: recordingOn,
            onChanged: recordingBusy ? null : _setRecording,
          ),
          // Capture mode (#457): "All" saves every detected dart; "Mistakes
          // only" saves just the frames you correct (the model's errors), so the
          // dataset isn't flooded with easy/correct examples. Only relevant —
          // and only enabled — while data collection is on.
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: Text(l10n.autoScorerCaptureModeTitle),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<CaptureMode>(
                segments: [
                  ButtonSegment(
                      value: CaptureMode.all,
                      label: Text(l10n.autoScorerCaptureModeAll)),
                  ButtonSegment(
                      value: CaptureMode.partial,
                      label: Text(l10n.autoScorerCaptureModeMistakes)),
                ],
                selected: {captureMode.value ?? CaptureMode.partial},
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
            title: Text(l10n.autoScorerExportTitle),
            subtitle: _exporting
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: _exportProgress),
                        const SizedBox(height: 4),
                        Text(l10n.autoScorerExportProgress(
                            StatFormatter.fmtPct(_exportProgress,
                                decimals: 0))),
                      ],
                    ),
                  )
                : Text(l10n.autoScorerExportSubtitle),
            onTap: _exporting ? null : () => _export(context),
          ),
          const Divider(),
          // Detection thresholds (#377 §3). The model's recall is measured at a
          // near-zero eval threshold, so a lower operating threshold recovers
          // borderline cal points / darts; expose both so they can be tuned
          // against the calibration overlay's per-cal confidence readout.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.autoScorerThresholdsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Plain-language help (#686 4a): orient a non-expert before they touch
          // the sliders, framed as the recall/false-positive trade-off.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.autoScorerThresholdsHelp),
          ),
          _ConfidenceSlider(
            icon: Icons.crop_free,
            label: l10n.autoScorerCalConfidenceLabel,
            value: calConf.value ?? kDefaultConfidence,
            enabled: !calConf.isLoading,
            onChanged: (v) =>
                ref.read(autoScorerCalConfidenceProvider.notifier).set(v),
          ),
          _ConfidenceSlider(
            icon: Icons.my_location,
            label: l10n.autoScorerDartConfidenceLabel,
            value: dartConf.value ?? kDefaultConfidence,
            enabled: !dartConf.isLoading,
            onChanged: (v) =>
                ref.read(autoScorerDartConfidenceProvider.notifier).set(v),
          ),
          // Technical display (#738): the plugin paints its own boxes labelled
          // with the raw class name and confidence (`cal1 82.4`), which is
          // debugging output, not something a player should read on top of
          // their board. Off by default; grouped here with the other
          // detection-tuning controls because it is what you turn on to see
          // what the sliders are doing.
          SwitchListTile(
            secondary: const Icon(Icons.developer_mode_outlined),
            title: Text(l10n.autoScorerTechnicalDisplayTitle),
            subtitle: Text(l10n.autoScorerTechnicalDisplaySubtitle),
            value: technical.value ?? false,
            onChanged: technical.isLoading
                ? null
                : (v) => ref
                    .read(autoScorerTechnicalDisplayProvider.notifier)
                    .setEnabled(v),
          ),
        ],
      ),
    );
  }

  /// Single export (#686): one `dartlodge-export-*.zip` holding the captured
  /// training frames (flat at the root — unchanged ingest contract) plus every
  /// recorded session as a self-contained bundle under `sessions/` (detection
  /// trace + correlated game events + game/competitors). Then offer to clear
  /// both stores.
  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final store = await ref.read(captureStoreProvider.future);
    if (!store.isSupported) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoScorerExportUnavailable)));
      return;
    }
    final captures = await store.list();

    // Bundle each recorded session into an in-memory JSON under sessions/.
    final sessionStore = await ref.read(sessionTraceStoreProvider.future);
    final sessionFiles = <({String archivePath, String content})>[];
    if (sessionStore.isSupported) {
      final ids = await sessionStore.list();
      final gameRepo = ref.read(gameRepositoryProvider);
      final eventRepo = ref.read(gameEventRepositoryProvider);
      for (final id in ids) {
        final trace = await sessionStore.read(id);
        if (trace == null) continue;
        final gameId = trace.header.gameId;
        final game = await gameRepo.getGame(gameId);
        if (game == null) continue; // game pruned — skip, don't fail the export
        final events = await eventRepo.getEventsForGame(gameId);
        final competitors = await gameRepo.getCompetitors(gameId);
        final bundle = SessionBundle(
            trace: trace, events: events, game: game, competitors: competitors);
        sessionFiles.add(
            (archivePath: 'sessions/$id.json', content: bundle.toJsonString()));
      }
    }

    if (captures.isEmpty && sessionFiles.isEmpty) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoScorerExportNothing)));
      return;
    }
    final frameCount = captures.length;
    final sessionCount = sessionFiles.length;
    final dest = await reserveExportZipPath();
    if (!mounted) return;
    setState(() {
      _exporting = true;
      _exportProgress = 0;
    });
    try {
      await store.writeExportZip(dest, extraFiles: sessionFiles,
          onProgress: (p) {
        if (mounted) setState(() => _exportProgress = p);
      });
    } catch (_) {
      // Streaming to disk can fail (e.g. storage full). Surface it rather than
      // letting it crash to a red screen — #468 wants the export to fail
      // gracefully with a message — and don't share a partial/missing zip.
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoScorerExportFailed)));
      return;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
    await shareCaptureZipFile(dest);
    // The export zips everything stored, so re-exporting re-includes what was
    // already shared. Offer to clear after the share sheet closes so it doesn't
    // pile up / re-export. Prompt (not auto-clear) because the share result
    // isn't reliable on Android — a cancelled share shouldn't wipe data.
    if (!context.mounted) return;
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.autoScorerClearTitle),
        content: Text(l10n.autoScorerClearBody(frameCount, sessionCount)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.autoScorerClearKeep)),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.autoScorerClearConfirm)),
        ],
      ),
    );
    if (clear == true) {
      await store.clear();
      if (sessionStore.isSupported) await sessionStore.clear();
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoScorerClearedToast)));
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
