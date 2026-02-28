import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/pages/game_config_page.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/game/presentation/widgets/player_selection_list_widget.dart';
import 'package:my_darts/features/players/presentation/providers/players_provider.dart';

class PlayerSelectionPage extends ConsumerStatefulWidget {
  const PlayerSelectionPage({super.key});

  @override
  ConsumerState<PlayerSelectionPage> createState() =>
      _PlayerSelectionPageState();
}

class _PlayerSelectionPageState extends ConsumerState<PlayerSelectionPage> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    // Guard: if state reverts to selectingType (e.g. reset()), go home.
    ref.listen(gameSetupProvider, (_, next) {
      next.maybeMap(
        selectingType: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/');
          });
        },
        orElse: () {},
      );
    });

    final setupState = ref.watch(gameSetupProvider);
    final notifier = ref.read(gameSetupProvider.notifier);

    final selectedIds = setupState.maybeMap(
      selectingPlayers: (s) => s.selectedPlayerIds.toSet(),
      orElse: () => <String>{},
    );

    final canStart = setupState.maybeMap(
      selectingPlayers: (s) => s.selectedPlayerIds.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final config = setupState.maybeMap(
                selectingPlayers: (s) => s.config,
                orElse: () => null,
              );
              if (config == null) return;

              final players = ref.read(allPlayersProvider).value ?? [];
              final panelPlayers = players
                  .where((p) => selectedIds.contains(p.playerId))
                  .map((p) => (id: p.playerId, name: p.name))
                  .toList();

              final result = await showModalBottomSheet<GameConfig>(
                context: context,
                isScrollControlled: true,
                builder: (_) => GameConfigPanel(
                  initialConfig: config,
                  players: panelPlayers,
                ),
              );

              if (result != null) {
                ref.read(gameSetupProvider.notifier).updateConfig(result);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(allPlayersProvider).when(
                  data: (players) => PlayerSelectionListWidget(
                    players: players,
                    lockedPlayerId: notifier.lockedPlayerId,
                    selectedIds: selectedIds,
                    onToggle: notifier.togglePlayer,
                    onAddNew: () async {
                      await context.push('/players/add');
                      ref.invalidate(allPlayersProvider);
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Failed to load players: $e')),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: (!canStart || _isStarting)
                  ? null
                  : () async {
                      final gameType = setupState.maybeMap(
                        selectingPlayers: (s) => s.gameType,
                        orElse: () => null,
                      );
                      setState(() => _isStarting = true);
                      final gameId = await notifier.startGame();
                      if (!mounted) return;
                      setState(() => _isStarting = false);
                      if (gameId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not start game. Please check your selection.',
                            ),
                          ),
                        );
                      } else {
                        final routeBase = switch (gameType) {
                          GameType.x01 => GameRoutes.activeX01,
                          GameType.cricket ||
                          GameType.blindCricket =>
                            GameRoutes.activeCricket,
                          _ => GameRoutes.activePractice,
                        };
                        context.go('$routeBase/$gameId');
                      }
                    },
              child: _isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('START GAME'),
            ),
          ),
        ],
      ),
    );
  }
}
