import 'package:flutter/material.dart';

/// One-time setup tips shown before the first aim (#393 setup flow). Educational
/// only — it teaches the framing that gets the most out of the detector. Pushed
/// as a transient route by the board overlay before the camera opens; pops with:
///   * `null`  — back / cancel (abort starting the camera)
///   * `false` — continue, keep showing next time
///   * `true`  — continue and don't show again ("remember")
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

  static const _tips = <({IconData icon, String title, String body})>[
    (
      icon: Icons.center_focus_strong,
      title: 'Fill the frame',
      body: 'Position the camera so the board fills most of the view, with all '
          'four corner markers visible. More board on screen means sharper '
          'scoring.',
    ),
    (
      icon: Icons.switch_camera_outlined,
      title: 'A slight side angle',
      body: 'A modest angle off head-on helps the camera see dart tips. Avoid '
          'extreme or perfectly face-on angles.',
    ),
    (
      icon: Icons.rotate_right,
      title: 'Any rotation is fine',
      body: "You don't need 20 at the top — the camera finds the markers in any "
          'board orientation.',
    ),
    (
      icon: Icons.light_mode_outlined,
      title: 'Good, even lighting',
      body: 'Avoid glare and deep shadows on the board so the markers stay '
          'clearly visible.',
    ),
    (
      icon: Icons.cleaning_services_outlined,
      title: 'Pull darts between turns',
      body: "Remove your darts each turn so they don't hide the tips of the next "
          'ones.',
    ),
    (
      icon: Icons.sports_outlined,
      title: 'Steel-tip boards',
      body: 'Auto-scoring is designed for steel-tip dartboards.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera setup tips')),
      body: ListView(
        children: [
          for (final tip in _tips)
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
                    title: const Text("Don't show this again"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_dontShowAgain),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Continue to camera'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
