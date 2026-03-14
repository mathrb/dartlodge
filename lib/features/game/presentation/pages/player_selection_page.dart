import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:my_darts/app/app_router.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/app_spacing.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/pages/game_config_page.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/presentation/providers/players_provider.dart';

// ── Top-level pure helpers ────────────────────────────────────────────────────

String _outStrategyLabel(String strategy) => switch (strategy) {
  'straight' => 'Straight',
  'double' => 'Double',
  'master' => 'Master',
  _ => strategy,
};

String _configSummaryFor(GameConfig config) {
  return config.maybeMap(
    x01: (c) {
      final legs = c.legsToWin;
      final legLabel = legs == 1 ? '1 Leg' : 'Best of $legs';
      return '${c.startingScore} · ${_outStrategyLabel(c.outStrategy)} Out · $legLabel';
    },
    cricket: (c) => '${c.variant} · ${c.pointsToWin} pts',
    aroundTheClock: (_) => 'Around the Clock',
    catch40: (_) => 'Catch 40',
    bobs27: (_) => "Bob's 27",
    shanghai: (c) => 'Shanghai · ${c.totalRounds} Rounds',
    checkoutPractice: (_) => '170 Checkout',
    orElse: () => 'Game',
  );
}

int? _maxPlayersFor(GameType type) {
  return switch (type) {
    GameType.x01 => 6,
    _ => null,
  };
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words[0][0].toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

// ── Main page ─────────────────────────────────────────────────────────────────

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
      selectingPlayers: (s) => s.selectedPlayerIds,
      orElse: () => const <String>[],
    );

    final config = setupState.maybeMap(
      selectingPlayers: (s) => s.config,
      orElse: () => null,
    );

    final gameType = setupState.maybeMap(
      selectingPlayers: (s) => s.gameType,
      orElse: () => null,
    );

    final canStart = notifier.canStart;
    final maxPlayers = gameType != null ? _maxPlayersFor(gameType) : null;

    final playersAsync = ref.watch(allPlayersProvider);
    final players = playersAsync.value ?? <Player>[];

    String nameFor(String id) =>
        players.firstWhere((p) => p.playerId == id, orElse: () {
          return Player(
            playerId: id,
            name: id,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          );
        }).name;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Players')),
      body: Column(
        children: [
          // Config summary chip
          if (config != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                0,
              ),
              child: _ConfigSummaryChip(
                config: config,
                onTap: () => _openConfigSheet(context, setupState),
              ),
            ),

          // Selected player area
          _SelectedPlayerArea(
            selectedPlayerIds: selectedIds,
            players: players,
            lockedPlayerId: notifier.lockedPlayerId,
            onTapPlayer: (id) => _openPlayerActionSheet(context, id, nameFor),
            onReorder: notifier.reorderPlayers,
          ),

          // Roster grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: playersAsync.when(
                data: (playerList) => _RosterGrid(
                  players: playerList,
                  selectedIds: selectedIds.toSet(),
                  maxPlayers: maxPlayers,
                  onTapPlayer: (id) {
                    final isSelected = selectedIds.contains(id);
                    if (isSelected) {
                      _openPlayerActionSheet(context, id, nameFor);
                    } else {
                      final atMax = maxPlayers != null &&
                          selectedIds.length >= maxPlayers;
                      if (!atMax) {
                        notifier.togglePlayer(id);
                      }
                    }
                  },
                  onAddPlayer: () => _openCreatePlayerSheet(context),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Failed to load players: $e')),
              ),
            ),
          ),

          // START GAME button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space4,
              ),
              child: Tooltip(
                message: canStart ? '' : 'Select at least one player',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (canStart && !_isStarting)
                        ? () => _onStartGame(context, notifier, gameType)
                        : null,
                    child: _isStarting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('START GAME'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modal openers ────────────────────────────────────────────────────────────

  Future<void> _openConfigSheet(
    BuildContext context,
    GameSetupState setupState,
  ) async {
    final config = setupState.maybeMap(
      selectingPlayers: (s) => s.config,
      orElse: () => null,
    );
    if (config == null) return;

    final result = await showModalBottomSheet<GameConfig>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => GameConfigPanel(
        initialConfig: config,
      ),
    );

    if (result != null && mounted) {
      ref.read(gameSetupProvider.notifier).updateConfig(result);
    }
  }

  void _openCreatePlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreatePlayerSheet(
        onPlayerCreated: (id) =>
            ref.read(gameSetupProvider.notifier).togglePlayer(id),
      ),
    );
  }

  void _openPlayerActionSheet(
    BuildContext context,
    String playerId,
    String Function(String) nameFor,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _PlayerActionSheet(
        playerName: nameFor(playerId),
        onDeselect: () =>
            ref.read(gameSetupProvider.notifier).togglePlayer(playerId),
      ),
    );
  }

  Future<void> _onStartGame(
    BuildContext context,
    GameSetupNotifier notifier,
    GameType? gameType,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _isStarting = true);
    try {
      final gameId = await notifier.startGame();
      if (!mounted) return;
      if (gameId == null) {
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Could not start game. Please check your selection.'),
          ),
        );
      } else {
        final routeBase = switch (gameType) {
          GameType.x01 => GameRoutes.activeX01,
          GameType.cricket || GameType.blindCricket => GameRoutes.activeCricket,
          _ => GameRoutes.activePractice,
        };
        router.go('$routeBase/$gameId');
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not start game. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _ConfigSummaryChip extends StatelessWidget {
  const _ConfigSummaryChip({required this.config, required this.onTap});

  final GameConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _configSummaryFor(config),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlayerArea extends StatelessWidget {
  const _SelectedPlayerArea({
    required this.selectedPlayerIds,
    required this.players,
    required this.lockedPlayerId,
    required this.onTapPlayer,
    required this.onReorder,
  });

  final List<String> selectedPlayerIds;
  final List<Player> players;
  final String? lockedPlayerId;
  final void Function(String id) onTapPlayer;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: selectedPlayerIds.isEmpty
            ? Center(
                child: Text(
                  'Select players below',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            : ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                onReorder: onReorder,
                itemCount: selectedPlayerIds.length,
                itemBuilder: (context, index) {
                  final id = selectedPlayerIds[index];
                  final name = players
                      .firstWhere(
                        (p) => p.playerId == id,
                        orElse: () => Player(
                          playerId: id,
                          name: id,
                          createdAt: DateTime.now(),
                          lastActive: DateTime.now(),
                        ),
                      )
                      .name;
                  return _SelectedPlayerCell(
                    key: ValueKey(id),
                    index: index,
                    name: name,
                    onTap: () => onTapPlayer(id),
                  );
                },
              ),
      ),
    );
  }
}

class _SelectedPlayerCell extends StatelessWidget {
  const _SelectedPlayerCell({
    super.key,
    required this.index,
    required this.name,
    required this.onTap,
  });

  final int index;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(name);
    final truncated =
        name.length > 10 ? '${name.substring(0, 9)}…' : name;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.secondaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              truncated,
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterGrid extends StatelessWidget {
  const _RosterGrid({
    required this.players,
    required this.selectedIds,
    required this.maxPlayers,
    required this.onTapPlayer,
    required this.onAddPlayer,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final int? maxPlayers;
  final void Function(String id) onTapPlayer;
  final VoidCallback onAddPlayer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = constraints.maxWidth / 4;
          final itemCount = players.length + 1; // +1 for add cell
          return SizedBox(
            height: cellHeight * 2.33,
            child: GridView.builder(
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == players.length) {
                  return _AddPlayerCell(onTap: onAddPlayer);
                }
                final player = players[index];
                final isSelected = selectedIds.contains(player.playerId);
                final atMax = maxPlayers != null &&
                    selectedIds.length >= maxPlayers! &&
                    !isSelected;
                return _PlayerRosterCell(
                  name: player.name,
                  isSelected: isSelected,
                  isDisabled: atMax,
                  maxPlayers: maxPlayers,
                  onTap: () => onTapPlayer(player.playerId),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PlayerRosterCell extends StatelessWidget {
  const _PlayerRosterCell({
    required this.name,
    required this.isSelected,
    required this.isDisabled,
    required this.maxPlayers,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final bool isDisabled;
  final int? maxPlayers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(name);
    final truncated = name.length > 8 ? '${name.substring(0, 7)}…' : name;

    Widget cell = InkWell(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: (isDisabled && !isSelected) ? 0.4 : 1.0,
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
                  isSelected ? cs.primary : cs.secondaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                  color: isSelected ? cs.onPrimary : cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            truncated,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDisabled && !isSelected
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );

    if (isDisabled && maxPlayers != null) {
      cell = Tooltip(
        message: 'Maximum $maxPlayers players reached',
        child: cell,
      );
    }

    return cell;
  }
}

class _AddPlayerCell extends StatelessWidget {
  const _AddPlayerCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.add, color: cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '+',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ── Create player sheet ───────────────────────────────────────────────────────

class _CreatePlayerSheet extends ConsumerStatefulWidget {
  const _CreatePlayerSheet({required this.onPlayerCreated});

  final ValueChanged<String> onPlayerCreated;

  @override
  ConsumerState<_CreatePlayerSheet> createState() => _CreatePlayerSheetState();
}

class _CreatePlayerSheetState extends ConsumerState<_CreatePlayerSheet> {
  final _nameController = TextEditingController();
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final player = Player(
        playerId: const Uuid().v4(),
        name: name,
        createdAt: now,
        lastActive: now,
      );
      await ref.read(playerRepositoryProvider).createPlayer(player);
      ref.invalidate(allPlayersProvider);
      if (mounted) {
        widget.onPlayerCreated(player.playerId);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(_nameController.text);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
        top: AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Avatar preview
          CircleAvatar(
            radius: 36,
            backgroundColor: cs.primaryContainer,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 24,
            decoration: InputDecoration(
              labelText: 'Player name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _createPlayer(),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isCreating ? null : _createPlayer,
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('CREATE PLAYER'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Player action sheet ───────────────────────────────────────────────────────

class _PlayerActionSheet extends StatelessWidget {
  const _PlayerActionSheet({
    required this.playerName,
    required this.onDeselect,
  });

  final String playerName;
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            playerName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(),
        Tooltip(
          message: 'Coming soon',
          child: ListTile(
            title: const Text('Handicap'),
            enabled: false,
            onTap: null,
          ),
        ),
        ListTile(
          title: const Text('Deselect'),
          onTap: () {
            onDeselect();
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
