import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/providers/players_providers.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/players_provider.dart';
import '../widgets/player_avatar_widget.dart';

class PlayerDetailPage extends ConsumerWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  /// Back navigation that survives a non-poppable stack: this page can be the
  /// only route after a deep link / app restoration, where `context.pop()`
  /// throws "There is nothing to pop". Falls back to the players list, the same
  /// guard `_confirmDelete` already uses.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(GameRoutes.players);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String playerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete player?'),
        content: Text('Delete $playerName? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final result = await ref
        .read(editPlayerProvider.notifier)
        .deletePlayer(playerId);

    if (!context.mounted) return;
    switch (result) {
      case DeletePlayerSuccess():
        _back(context);
      case DeletePlayerHasGameHistory():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete a player with game history'),
          ),
        );
      case DeletePlayerUnexpectedError():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete player. Please try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlayer = ref.watch(playerProvider(playerId));

    return asyncPlayer.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingSpinnerWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load player: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _back(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
      data: (player) {
        if (player == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player not found')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Player not found'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _back(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(player.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push(
                  '/players/$playerId/edit',
                  extra: player.name,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _confirmDelete(context, ref, player.name),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: PlayerAvatarWidget(player: player, size: 96),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    player.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Member since ${DateFormat.yMMMd().format(player.createdAt.toLocal())}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Center(
                  child: Text(
                    'Last active ${DateFormat.yMMMd().format(player.lastActive.toLocal())}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      title: const Text('Career Statistics'),
                      trailing: FilledButton(
                        onPressed: () =>
                            context.push('/stats/player/$playerId'),
                        child: const Text('VIEW STATISTICS'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
