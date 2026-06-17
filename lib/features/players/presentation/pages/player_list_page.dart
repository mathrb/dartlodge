import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/presentation/providers/players_provider.dart';
import 'package:dart_lodge/features/players/presentation/widgets/player_card_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

class PlayerListPage extends ConsumerWidget {
  const PlayerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(GameRoutes.home);
            }
          },
        ),
        title: Text(l10n.playersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.playersAddPlayerTooltip,
            onPressed: () => context.push('/players/add'),
          ),
        ],
      ),
      body: ref.watch(allPlayersProvider).when(
        data: (players) => players.isEmpty
            ? const _EmptyState()
            : _PlayerList(players: players),
        loading: () => const _SkeletonList(),
        error: (error, _) => ErrorRetryWidget(
          title: l10n.playersLoadListFailed,
          message: error.toString(),
          onRetry: () => ref.invalidate(allPlayersProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/players/add'),
        tooltip: l10n.playersAddPlayerTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.playersNoPlayersYet,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.push('/players/add'),
            child: Text(l10n.playersAddFirstPlayer),
          ),
        ],
      ),
    );
  }
}

class _PlayerList extends ConsumerWidget {
  final List<Player> players;

  const _PlayerList({required this.players});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        return PlayerCardWidget(
          player: p,
          onTap: () => context.push('/stats/player/${p.playerId}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/players/${p.playerId}/edit', extra: p.name);
              }
              if (value == 'delete') _showDeleteConfirmation(context, ref, p);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.commonEdit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.commonDelete)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playersDeleteTitle),
        content: Text(l10n.playersDeleteConfirm(player.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final result = await ref
        .read(editPlayerProvider.notifier)
        .deletePlayer(player.playerId);

    if (!context.mounted) return;
    switch (result) {
      case DeletePlayerSuccess():
        // List rebuilds via the invalidated `allPlayersProvider`; no
        // page-level navigation needed here.
        break;
      case DeletePlayerHasGameHistory():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playersCannotDeleteWithHistory)),
        );
      case DeletePlayerUnexpectedError():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playersDeleteFailed)),
        );
    }
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

