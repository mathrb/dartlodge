import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/history/presentation/widgets/game_summary_card_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Floor passed to `showDateRangePicker.firstDate`. Chosen pragmatically
/// as "before any game in this app could plausibly exist" — DartLodge
/// shipped its first build in 2026 and no migration brings in older
/// data, so 2020 is comfortably below the earliest possible game date.
/// Kept as a single named constant rather than a magic literal so a
/// future "tie firstDate to the earliest persisted game" provider can
/// replace this site without code-archaeology.
final DateTime _kFilterFirstDate = DateTime(2020);

class HistoryFilterBarWidget extends StatelessWidget {
  final GameType? selectedGameType;
  final DateTime? selectedDateFrom;
  final DateTime? selectedDateTo;
  final ValueChanged<GameType?> onGameTypeChanged;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const HistoryFilterBarWidget({
    required this.selectedGameType,
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.onGameTypeChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
    super.key,
  });

  String _formatDateShort(DateTime d) => DateFormat('d MMM').format(d);

  bool get _isFilterActive =>
      selectedGameType != null ||
      selectedDateFrom != null ||
      selectedDateTo != null;

  Future<void> _pickDateRange(BuildContext context) async {
    final initial =
        (selectedDateFrom != null && selectedDateTo != null)
            ? DateTimeRange(start: selectedDateFrom!, end: selectedDateTo!)
            : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: _kFilterFirstDate,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRange = selectedDateFrom != null && selectedDateTo != null;
    final dateLabel = hasRange
        ? '${_formatDateShort(selectedDateFrom!)} – ${_formatDateShort(selectedDateTo!)}'
        : l10n.historyFilterDateRange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<GameType?>(
              initialValue: selectedGameType,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: l10n.historyFilterGameType,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: <DropdownMenuItem<GameType?>>[
                DropdownMenuItem<GameType?>(
                  value: null,
                  child: Text(l10n.historyFilterAll),
                ),
                ...GameType.values.map(
                  (t) => DropdownMenuItem<GameType?>(
                    value: t,
                    child: Text(
                      GameSummaryCardWidget.gameTypeName(t),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: onGameTypeChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                dateLabel,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
              onPressed: () => _pickDateRange(context),
            ),
          ),
          if (_isFilterActive) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.historyFilterClear,
              onPressed: onClearFilters,
            ),
          ],
        ],
      ),
    );
  }
}
