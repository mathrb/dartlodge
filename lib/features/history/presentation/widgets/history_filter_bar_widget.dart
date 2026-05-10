import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/history/presentation/widgets/game_summary_card_widget.dart';

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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = selectedDateFrom != null && selectedDateTo != null;
    final dateLabel = hasRange
        ? '${_formatDateShort(selectedDateFrom!)} – ${_formatDateShort(selectedDateTo!)}'
        : 'Date Range';

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
              decoration: const InputDecoration(
                labelText: 'Game type',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: <DropdownMenuItem<GameType?>>[
                const DropdownMenuItem<GameType?>(
                  value: null,
                  child: Text('All'),
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
              tooltip: 'Clear filters',
              onPressed: onClearFilters,
            ),
          ],
        ],
      ),
    );
  }
}
