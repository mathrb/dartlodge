import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/core/utils/constants.dart';

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

  String _formatDate(DateTime d) => DateFormat('d MMM y').format(d);

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
    final dateLabel =
        selectedDateFrom != null && selectedDateTo != null
            ? '${_formatDate(selectedDateFrom!)} – ${_formatDate(selectedDateTo!)}'
            : 'Date Range';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedGameType == null,
            onSelected: (_) => onGameTypeChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('X01'),
            selected: selectedGameType == GameType.x01,
            onSelected: (_) => onGameTypeChanged(GameType.x01),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Cricket'),
            selected: selectedGameType == GameType.cricket,
            onSelected: (_) => onGameTypeChanged(GameType.cricket),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(dateLabel),
            onPressed: () => _pickDateRange(context),
          ),
          if (_isFilterActive) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              onPressed: onClearFilters,
            ),
          ],
        ],
      ),
    );
  }
}
