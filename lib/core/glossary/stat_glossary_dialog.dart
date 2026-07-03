import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../utils/app_text_styles.dart';
import 'stat_term.dart';

/// Shows a plain-language definition of a statistics [term] in a simple
/// [AlertDialog], mirroring the confirm-dialog pattern used elsewhere
/// (e.g. `settings_page.dart`). UI-only helper for #719.
Future<void> showStatGlossaryDialog(BuildContext context, StatTerm term) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(term.title(l10n)),
        content: Text(
          term.body(l10n),
          style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonDone),
          ),
        ],
      );
    },
  );
}
