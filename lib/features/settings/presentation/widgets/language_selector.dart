import 'package:flutter/material.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

import '../../../../l10n/supported_locales.dart';

/// Sentinel for the "follow the system" choice inside the picker dialog —
/// distinct from any real language code, and from a dismissed dialog (`null`).
const _kSystemSentinel = '__system__';

/// Settings control for choosing the app language.
///
/// [value] is the explicit override (`null` = follow the device locale). The
/// row label is localized; the options list "System default" plus the language
/// autonyms ([kLanguageAutonyms]). Picking an option calls [onChanged] with the
/// chosen [Locale] (or `null` for system); dismissing the dialog is a no-op.
class LanguageSelector extends StatelessWidget {
  final Locale? value;
  final ValueChanged<Locale?> onChanged;

  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _currentLabel(AppLocalizations l10n) => value == null
      ? l10n.languageSystemDefault
      : (kLanguageAutonyms[value!.languageCode] ?? value!.languageCode);

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = value == null ? _kSystemSentinel : value!.languageCode;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsLanguageLabel),
        children: [
          // toggleable: tapping the already-selected row still fires onChanged
          // (with null) and pops, so the dialog can always be closed by tapping
          // any row — without it, tapping the current option is a no-op and the
          // dialog (which has no Cancel button) traps the user.
          RadioListTile<String>(
            value: _kSystemSentinel,
            groupValue: selected,
            toggleable: true,
            title: Text(l10n.languageSystemDefault),
            onChanged: (v) => Navigator.pop(ctx, v ?? _kSystemSentinel),
          ),
          for (final locale in kSupportedLocales)
            RadioListTile<String>(
              value: locale.languageCode,
              groupValue: selected,
              toggleable: true,
              title: Text(
                kLanguageAutonyms[locale.languageCode] ?? locale.languageCode,
              ),
              onChanged: (v) => Navigator.pop(ctx, v ?? locale.languageCode),
            ),
        ],
      ),
    );

    if (result == null) return; // dismissed — no change
    onChanged(result == _kSystemSentinel ? null : Locale(result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguageLabel),
      trailing: Text(
        _currentLabel(l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () => _pick(context),
    );
  }
}
