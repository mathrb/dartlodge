import 'package:flutter/material.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/presentation/widgets/player_avatar_widget.dart';

class PlayerSelectionListWidget extends StatelessWidget {
  const PlayerSelectionListWidget({
    super.key,
    required this.players,
    required this.lockedPlayerId,
    required this.selectedIds,
    required this.onToggle,
    required this.onAddNew,
  });

  final List<Player> players;
  final String? lockedPlayerId;
  final Set<String> selectedIds;
  final void Function(String) onToggle;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...players.map((player) {
          final isLocked = player.playerId == lockedPlayerId;
          if (isLocked) {
            return ListTile(
              leading: PlayerAvatarWidget(player: player),
              title: Text(player.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 4),
                  Checkbox(value: true, onChanged: null),
                ],
              ),
            );
          }
          return ListTile(
            leading: PlayerAvatarWidget(player: player),
            title: Text(player.name),
            trailing: Checkbox(
              value: selectedIds.contains(player.playerId),
              onChanged: (_) => onToggle(player.playerId),
            ),
            onTap: () => onToggle(player.playerId),
          );
        }),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('＋ Add New Player'),
          onTap: onAddNew,
        ),
      ],
    );
  }
}
