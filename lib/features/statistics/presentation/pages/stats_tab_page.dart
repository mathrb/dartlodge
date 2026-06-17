import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/relative_date.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

class StatsTabPage extends ConsumerWidget {
  const StatsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: AppHeader(
                showBack: true,
                onBack: () => context.go(GameRoutes.home),
              ),
            ),
            Expanded(
              child: ref.watch(allPlayersProvider).when(
                data: (players) => players.isEmpty
                    ? const _EmptyState()
                    : _PlayerPickerList(players: players),
                loading: () => const LoadingSpinnerWidget(),
                error: (e, _) => ErrorRetryWidget(
                  message: l10n.statsPlayersLoadFailed(e.toString()),
                  onRetry: () => ref.invalidate(allPlayersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerPickerList extends StatelessWidget {
  final List<Player> players;

  const _PlayerPickerList({required this.players});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: Text(
            l10n.statsSelectPlayer,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, i) {
              final p = players[i];
              return _StatsPlayerTile(
                player: p,
                onTap: () => context.push(GameRoutes.playerStats(p.playerId)),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact roster cell for the stats tab. Inlined here (rather than importing
/// `PlayerCardWidget` from the players feature) to keep stats from depending
/// on another feature's presentation layer.
class _StatsPlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const _StatsPlayerTile({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    final color = palette[player.playerId.hashCode.abs() % palette.length];
    final initial =
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minTileHeight: 64,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: Text(
          initial,
          style: const TextStyle(fontSize: 18, color: AppColors.onAvatar),
        ),
      ),
      title: Text(player.name),
      subtitle: Text(
        AppLocalizations.of(context)
            .playersCardLastActive(_formatLastActive(context)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatLastActive(BuildContext context) {
    return relativeDayLabel(context, player.lastActive) ??
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(player.lastActive.toLocal());
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
            Icons.bar_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.playersNoPlayersYet,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statsAddPlayersHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
