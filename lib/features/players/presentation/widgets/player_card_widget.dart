import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const PlayerCardWidget({super.key, required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        trailing: const Icon(Icons.chevron_right),
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
