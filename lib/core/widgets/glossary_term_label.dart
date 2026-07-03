import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../glossary/stat_glossary_dialog.dart';
import '../glossary/stat_term.dart';
import '../utils/app_spacing.dart';
import '../utils/app_theme.dart';

/// A stat label that advertises a tappable definition: the [label] text
/// followed by a small info glyph in the accent colour. Tapping it opens
/// [showStatGlossaryDialog] for [term] (#719).
///
/// The caller passes the already-cased display string ([label]) so the widget
/// stays casing-agnostic — stats tables use normal case, the recap breakdown
/// upper-cases.
class GlossaryTermLabel extends StatelessWidget {
  const GlossaryTermLabel({
    required this.label,
    required this.term,
    this.style,
    this.textAlign,
    super.key,
  });

  final String label;
  final StatTerm term;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: term.title(l10n),
      child: InkWell(
        onTap: () => showStatGlossaryDialog(context, term),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: style,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Icon(Icons.info_outline, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
