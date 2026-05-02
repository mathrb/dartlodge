import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/presentation/widgets/player_avatar_widget.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PlayerCardWidget({
    super.key,
    required this.player,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minTileHeight: 64,
      leading: PlayerAvatarWidget(player: player, size: 40),
      title: Text(player.name),
      subtitle: Text('Last active: ${_formatLastActive(player.lastActive)}'),
      trailing: trailing,
      onTap: onTap,
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
