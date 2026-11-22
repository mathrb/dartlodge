import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact_email.dart';

/// Launches a URI; injectable so tests do not touch the platform channel.
typedef UriLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLauncher(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Builds the `mailto:` URI for the Contact-us row. The subject carries the
/// app [version] so incoming mail is triaged without asking for it.
Uri contactMailtoUri({String? version}) => Uri(
      scheme: 'mailto',
      path: kDartLodgeContactEmail,
      // `query` (not `queryParameters`) so spaces encode as %20 — mail
      // clients do not decode `+` back into spaces.
      query: 'subject=${Uri.encodeComponent(
        version == null ? 'DartLodge feedback' : 'DartLodge feedback (v$version)',
      )}',
    );

/// Open a draft e-mail to [kDartLodgeContactEmail] in the device's mail app.
///
/// Unlike "Report a Bug" this works with crash reporting turned off. When no
/// mail app can handle the URI (common on web or a device without one), the
/// address is copied to the clipboard and a snackbar says so, so the tap is
/// never a silent no-op.
Future<void> openContactEmail(
  BuildContext context, {
  String? version,
  UriLauncher launcher = _defaultLauncher,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  var launched = false;
  try {
    launched = await launcher(contactMailtoUri(version: version));
  } catch (_) {
    launched = false;
  }
  if (launched) return;
  await Clipboard.setData(const ClipboardData(text: kDartLodgeContactEmail));
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.settingsContactNoMailApp)),
  );
}
