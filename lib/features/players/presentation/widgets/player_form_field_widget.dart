import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dart_lodge/features/players/domain/validators.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

class PlayerFormFieldWidget extends StatelessWidget {
  const PlayerFormFieldWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final PlayerNameError? error;

  String? _errorText(AppLocalizations l10n) => switch (error) {
        PlayerNameError.empty => l10n.playersNameEmpty,
        PlayerNameError.tooLong => l10n.playersNameTooLong,
        PlayerNameError.duplicate => l10n.playersNameExists,
        PlayerNameError.unknown => l10n.playersNameErrorGeneric,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      maxLength: 30,
      inputFormatters: [LengthLimitingTextInputFormatter(30)],
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: l10n.commonName,
        errorText: _errorText(l10n),
      ),
    );
  }
}
