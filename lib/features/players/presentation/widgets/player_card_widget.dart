import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlayerCardWidget({
    super.key,
    required this.player,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasMenu = onEdit != null || onDelete != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?'),
        ),
        title: Text(player.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          'Last active: ${_formatLastActive(player.lastActive)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: hasMenu
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String _formatLastActive(DateTime lastActive) {
  final now = DateTime.now();
  final local = lastActive.toLocal();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  return DateFormat.yMMMd().format(local);
}
