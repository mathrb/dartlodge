import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// One-time setup tips shown before the first aim (#393 setup flow). Educational
/// only — it teaches the framing that gets the most out of the detector. Pushed
/// as a transient route by the board overlay before the camera opens; on that
/// game-flow path (`reviewOnly: false`) it pops with:
///   * `null`  — back / cancel (abort starting the camera)
///   * `false` — continue, keep showing next time
///   * `true`  — continue and don't show again ("remember")
/// In review mode (`reviewOnly: true`) there is no Continue action, so it only
/// ever pops `null` via the AppBar back button.
///
/// Riverpod-free (like the aim view): the parent reads/writes the "seen" pref and
/// reacts to the popped value. Holds only the local checkbox state.
///
/// [reviewOnly] is for the Settings entry, where the screen is opened just to
/// re-read the tips — there is no camera to continue to. It hides the "Don't
/// show this again" checkbox and the "Continue to camera" button (the AppBar
/// back button dismisses), so those controls only appear on the game-flow path
/// where they mean something.
class AutoScorerSetupTipsView extends StatefulWidget {
  const AutoScorerSetupTipsView({super.key, this.reviewOnly = false});

  /// When true (opened from Settings), hide the checkbox + "Continue" action.
  final bool reviewOnly;

  @override
  State<AutoScorerSetupTipsView> createState() =>
      _AutoScorerSetupTipsViewState();
}

class _AutoScorerSetupTipsViewState extends State<AutoScorerSetupTipsView> {
  bool _dontShowAgain = false;

  List<({IconData icon, String title, String body})> _tips(
          AppLocalizations l10n) =>
      [
        (
          icon: Icons.center_focus_strong,
          title: l10n.autoScorerTip1Title,
          body: l10n.autoScorerTip1Body,
        ),
        (
          icon: Icons.switch_camera_outlined,
          title: l10n.autoScorerTip2Title,
          body: l10n.autoScorerTip2Body,
        ),
        (
          icon: Icons.rotate_right,
          title: l10n.autoScorerTip3Title,
          body: l10n.autoScorerTip3Body,
        ),
        (
          icon: Icons.light_mode_outlined,
          title: l10n.autoScorerTip4Title,
          body: l10n.autoScorerTip4Body,
        ),
        (
          icon: Icons.cleaning_services_outlined,
          title: l10n.autoScorerTip5Title,
          body: l10n.autoScorerTip5Body,
        ),
        (
          icon: Icons.sports_outlined,
          title: l10n.autoScorerTip6Title,
          body: l10n.autoScorerTip6Body,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoScorerSetupTipsTile)),
      body: ListView(
        children: [
          for (final tip in _tips(l10n))
            ListTile(
              leading: Icon(tip.icon),
              title: Text(tip.title),
              subtitle: Text(tip.body),
            ),
        ],
      ),
      // Checkbox + action live in the bottom bar so they stay reachable without
      // scrolling past every tip. Hidden in review mode (Settings): there's no
      // camera to continue to and nothing to remember — back dismisses.
      bottomNavigationBar: widget.reviewOnly
          ? null
          : SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _dontShowAgain,
                    onChanged: (v) =>
                        setState(() => _dontShowAgain = v ?? false),
                    title: Text(l10n.autoScorerDontShowAgain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_dontShowAgain),
                      icon: const Icon(Icons.videocam_outlined),
                      label: Text(l10n.autoScorerContinueToCamera),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
