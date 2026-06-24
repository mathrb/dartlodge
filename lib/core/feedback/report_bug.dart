import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Whether the in-app "Report a Bug" flow can actually deliver feedback.
///
/// Crash reporting is opt-out (see `lib/main.dart`): when disabled, Sentry is
/// never initialized this run and its hub is a no-op `NoOpHub`, so
/// `captureFeedback` would silently drop the message. Callers gate the entry
/// point (Settings row, in-game menu item) on this so feedback is never lost.
bool isBugReportingAvailable() => Sentry.isEnabled;

/// Show the shared "Report a Bug" dialog and submit the message via Sentry
/// feedback (#688).
///
/// Lifted to `core/` so both Settings and the in-game board menus can use it
/// without one feature importing another. Callers should gate visibility on
/// [isBugReportingAvailable]; this function itself still captures
/// unconditionally (a no-op when Sentry is disabled).
Future<void> showReportBugDialog(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final message = await showDialog<String>(
    context: context,
    builder: (_) => const _ReportBugDialog(),
  );
  if (message == null || message.isEmpty) return;

  Sentry.captureFeedback(SentryFeedback(message: message));

  if (context.mounted) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsReportBugThanks)),
    );
  }
}

/// The dialog owns its [TextEditingController] so it is disposed in
/// [State.dispose] — after the route's exit transition — instead of being
/// disposed synchronously the instant `showDialog` returns (which left the
/// still-animating `TextField` reading a disposed controller).
class _ReportBugDialog extends StatefulWidget {
  const _ReportBugDialog();

  @override
  State<_ReportBugDialog> createState() => _ReportBugDialogState();
}

class _ReportBugDialogState extends State<_ReportBugDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsReportBug),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: l10n.settingsReportBugHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.commonSend),
        ),
      ],
    );
  }
}
