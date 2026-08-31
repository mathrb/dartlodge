import 'package:dart_lodge/features/auto_scorer/domain/sharing/export_destination.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the player chose on the pre-send screen.
///
/// [send] false means the share sheet is never opened — the zip stays on the
/// device and nothing leaves it. [dontShowAgain] is the repeat sender saying
/// they know the drill; the caller persists it.
typedef PreSendChoice = ({bool send, bool dontShowAgain});

/// The screen shown before the export is handed to the OS share sheet (#744,
/// design S3).
///
/// Export used to hand a zip straight to the share sheet: no statement of what
/// was inside, no reminder that it holds photographs of the player's board and
/// room, and no destination — so in practice it led nowhere. This says all
/// three, and gives the two-step route to the maintainer.
///
/// **Transport is unchanged**: the share sheet is still what sends the file.
/// This screen only makes the hand-off understandable.
///
/// Riverpod-free like the setup tips (the caller owns the "skip next time"
/// pref); pops a [PreSendChoice], or null when dismissed with the back button
/// — which the caller must read as "do not send".
class AutoScorerPreSendView extends StatefulWidget {
  const AutoScorerPreSendView({
    super.key,
    required this.photoCount,
    required this.sessionCount,
    required this.sizeLabel,
  });

  /// Training photos in the zip.
  final int photoCount;

  /// Recorded sessions bundled under `sessions/`.
  final int sessionCount;

  /// Pre-formatted size of the zip (the caller formats it, so this stays a
  /// pure widget).
  final String sizeLabel;

  @override
  State<AutoScorerPreSendView> createState() => _AutoScorerPreSendViewState();
}

class _AutoScorerPreSendViewState extends State<AutoScorerPreSendView> {
  bool _dontShowAgain = false;

  Future<void> _copyAddress() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        const ClipboardData(text: kAutoScorerExportContact));
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.autoScorerPreSendAddressCopied)));
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoScorerPreSendTitle)),
      body: ListView(
        children: [
          _section(context, l10n.autoScorerPreSendContentsTitle, [
            Text(l10n.autoScorerPreSendPhotos(widget.photoCount), style: body),
            Text(l10n.autoScorerPreSendSessions(widget.sessionCount),
                style: body),
            Text(l10n.autoScorerPreSendSize(widget.sizeLabel), style: body),
          ]),
          // The photos are of the player's room, not just their board. Saying
          // so before the share sheet is the whole point of this screen.
          _section(context, l10n.autoScorerPreSendPhotosTitle, [
            Text(l10n.autoScorerPreSendPhotosBody, style: body),
          ]),
          _section(context, l10n.autoScorerPreSendWhereTitle, [
            Text(l10n.autoScorerPreSendStep1, style: body),
            const SizedBox(height: 8),
            // The address is interpolated from one constant, and the reason
            // for the Drive detour is stated: without it, players try to
            // e-mail the zip, fail on the attachment limit, and give up.
            Text(l10n.autoScorerPreSendStep2(kAutoScorerExportContact),
                style: body),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _copyAddress,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.autoScorerPreSendCopyAddress),
              ),
            ),
          ]),
          _section(context, l10n.autoScorerPreSendNextTitle, [
            Text(l10n.autoScorerPreSendNextBody, style: body),
          ]),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              title: Text(l10n.autoScorerDontShowAgain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                        (send: false, dontShowAgain: _dontShowAgain)),
                    child: Text(l10n.autoScorerPreSendNotNow),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                        (send: true, dontShowAgain: _dontShowAgain)),
                    icon: const Icon(Icons.ios_share),
                    label: Text(l10n.autoScorerPreSendShare),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
