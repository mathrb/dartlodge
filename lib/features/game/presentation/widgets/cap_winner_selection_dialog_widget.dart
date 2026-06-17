import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../domain/models/game_state.dart';

/// Mandatory dialog for ambiguous round-cap leg termination — user must pick
/// a winner; dismiss via back/barrier is blocked.
class CapWinnerSelectionDialogWidget extends StatefulWidget {
  const CapWinnerSelectionDialogWidget({
    required this.competitors,
    required this.onSelect,
    super.key,
  });

  final List<CompetitorState> competitors;
  final ValueChanged<String> onSelect;

  @override
  State<CapWinnerSelectionDialogWidget> createState() =>
      _CapWinnerSelectionDialogWidgetState();
}

class _CapWinnerSelectionDialogWidgetState
    extends State<CapWinnerSelectionDialogWidget> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(l10n.gameRoundLimitReached),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.gameNoAutoWinner,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.competitors.map((c) {
                final selected = _selectedId == c.competitorId;
                return ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedId = c.competitorId),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: _selectedId == null
                ? null
                : () {
                    final id = _selectedId!;
                    Navigator.of(context).pop();
                    widget.onSelect(id);
                  },
            child: Text(l10n.gameSetWinner),
          ),
        ],
      ),
    );
  }
}
