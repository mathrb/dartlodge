import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/pages/game_config_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/providers/statistics_providers.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';

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
      final rounds = c.totalRounds;
      final roundsLabel = rounds == null ? '∞ Rounds' : (rounds == 1 ? '1 Round' : '$rounds Rounds');
      return '${c.startingScore} · ${_outStrategyLabel(c.outStrategy)} Out · $roundsLabel';
    },
    cricket: (c) {
      final rounds = c.totalRounds;
      final roundsLabel = rounds == null ? '∞ Rounds' : (rounds == 1 ? '1 Round' : '$rounds Rounds');
      return '${c.variant} · $roundsLabel · ${c.legsToWin} ${c.legsToWin == 1 ? 'leg' : 'legs'}';
    },
    aroundTheClock: (_) => 'Around the Clock',
    catch40: (_) => 'Catch 40',
    bobs27: (_) => "Bob's 27",
    shanghai: (c) => 'Shanghai · ${c.totalRounds} Rounds',
    countUp: (c) => 'Count-Up · ${c.totalRounds} Rounds',
    checkoutPractice: (_) => '170 Checkout',
    orElse: () => 'Game',
  );
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
            if (mounted) context.go(GameRoutes.home);
          });
        },
        orElse: () {},
      );
    });

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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

    final playerHandicaps = setupState.maybeMap(
      selectingPlayers: (s) => s.playerHandicaps,
      orElse: () => const <String, int>{},
    );
    final isX01 = config is X01GameConfig;
    final isCountUp = config is CountUpGameConfig;
    // Per-game-type handicap value lists. X01 stores negatives (handicap
    // SUBTRACTS from the starting score); count-up stores positives (handicap
    // ADDS to the initial 0). The chip renders the sign automatically.
    const x01HandicapValues = [0, -50, -100, -150, -200];
    final countUpHandicapValues =
        GameConfigurationConstants.countUpAllowedHandicaps;
    final handicapValues = isX01
        ? x01HandicapValues
        : isCountUp
            ? countUpHandicapValues
            : const <int>[];
    final showHandicap = isX01 || isCountUp;

    final canStart = notifier.canStart;
    final maxPlayers = gameType != null ? gameType.maxPlayers : null;

    final playersAsync = ref.watch(allPlayersProvider);
    final players = playersAsync.value ?? <Player>[];

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
                onBack: () => context.pop(),
                trailing: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: cs.onSurface,
                    semanticLabel: 'Settings',
                  ),
                  tooltip: 'Settings',
                  onPressed: () => context.push(GameRoutes.settings),
                ),
              ),
            ),

            // Config summary chip (centered pill)
            if (config != null)
              Center(
                child: _ConfigSummaryChip(
                  config: config,
                  onTap: () => _openConfigSheet(context, setupState),
                ),
              ),

            // Active Lineup header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Text(
                    'ACTIVE LINEUP',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    maxPlayers != null
                        ? '${selectedIds.length} / $maxPlayers Players'
                        : '${selectedIds.length} ${selectedIds.length == 1 ? 'Player' : 'Players'}',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Active lineup cards
            _ActiveLineup(
              selectedPlayerIds: selectedIds,
              players: players,
              onReorder: notifier.reorderPlayers,
              onRemove: (id) => notifier.togglePlayer(id),
              playerHandicaps: playerHandicaps,
              onHandicapChanged: showHandicap
                  ? (id, h) => notifier.setPlayerHandicap(id, h)
                  : null,
              handicapValues: handicapValues,
            ),

            // Roster section header + add button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Text(
                    'ROSTER',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _openCreatePlayerSheet(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    splashColor: AppTheme.kineticSplashColor,
                    highlightColor: AppTheme.kineticSplashColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 14,
                            color: cs.primaryFixed,
                            semanticLabel: 'Add new player',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'NEW PLAYER',
                            style: tt.labelSmall?.copyWith(color: cs.primaryFixed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                        notifier.togglePlayer(id);
                      } else {
                        final atMax = maxPlayers != null &&
                            selectedIds.length >= maxPlayers;
                        if (!atMax) notifier.togglePlayer(id);
                      }
                    },
                  ),
                  loading: () => const LoadingSpinnerWidget(),
                  error: (e, _) => ErrorRetryWidget(
                    message: 'Failed to load players: $e',
                    onRetry: () => ref.invalidate(allPlayersProvider),
                  ),
                ),
              ),
            ),

            // START GAME button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space3,
                AppSpacing.space4,
                AppSpacing.space4,
              ),
              child: Tooltip(
                message: canStart ? '' : 'Select at least one player',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primaryFixed,
                      foregroundColor: AppColors.onPrimaryFixed,
                      disabledBackgroundColor:
                          cs.primaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                      disabledForegroundColor:
                          AppColors.onPrimaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                      minimumSize: const Size.fromHeight(56),
                      textStyle: tt.labelLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    onPressed: (canStart && !_isStarting)
                        ? () => _onStartGame(context, notifier, gameType)
                        : null,
                    icon: _isStarting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.sports_score,
                            semanticLabel: 'Start game',
                          ),
                    label: const Text('START GAME'),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        onPlayerCreated: (id) {
          final state = ref.read(gameSetupProvider);
          final gameType = state.maybeMap(
            selectingPlayers: (s) => s.gameType,
            orElse: () => null,
          );
          final maxPlayers = gameType != null ? gameType.maxPlayers : null;
          final selectedCount = state.maybeMap(
            selectingPlayers: (s) => s.selectedPlayerIds.length,
            orElse: () => 0,
          );
          final atMax = maxPlayers != null && selectedCount >= maxPlayers;
          if (!atMax) {
            ref.read(gameSetupProvider.notifier).togglePlayer(id);
          }
        },
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
          GameType.cricket => GameRoutes.activeCricket,
          GameType.countUp => GameRoutes.activeCountUp,
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

// ── Config summary chip ────────────────────────────────────────────────────────

class _ConfigSummaryChip extends StatelessWidget {
  const _ConfigSummaryChip({required this.config, required this.onTap});

  final GameConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      splashColor: AppTheme.kineticSplashColor,
      highlightColor: AppTheme.kineticSplashColor,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space5,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_input_component,
              size: 16,
              color: cs.primaryFixed,
              semanticLabel: 'Game configuration',
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              _configSummaryFor(config),
              style: tt.labelMedium?.copyWith(
                color: cs.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: cs.onSurfaceVariant,
              semanticLabel: 'Edit game config',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Lineup ─────────────────────────────────────────────────────────────

class _ActiveLineup extends StatelessWidget {
  const _ActiveLineup({
    required this.selectedPlayerIds,
    required this.players,
    required this.onReorder,
    required this.onRemove,
    this.playerHandicaps = const {},
    this.onHandicapChanged,
    this.handicapValues = const [],
  });

  final List<String> selectedPlayerIds;
  final List<Player> players;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String id) onRemove;
  final Map<String, int> playerHandicaps;
  final void Function(String playerId, int handicap)? onHandicapChanged;
  final List<int> handicapValues;

  Player _playerById(String id) => players.firstWhere(
    (p) => p.playerId == id,
    orElse: () => Player(
      playerId: id,
      name: id,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (selectedPlayerIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space5,
          horizontal: AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 28,
              color: cs.onSurfaceVariant,
              semanticLabel: 'No players selected',
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Tap a player from the roster to add',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorder: onReorder,
        itemCount: selectedPlayerIds.length,
        itemBuilder: (context, index) {
          final id = selectedPlayerIds[index];
          final player = _playerById(id);
          return _ActivePlayerCard(
            key: ValueKey(id),
            index: index,
            player: player,
            onRemove: () => onRemove(id),
            handicap: playerHandicaps[id] ?? 0,
            onHandicapChanged: onHandicapChanged != null
                ? (h) => onHandicapChanged!(id, h)
                : null,
            handicapValues: handicapValues,
          );
        },
      ),
    );
  }
}

class _ActivePlayerCard extends ConsumerWidget {
  const _ActivePlayerCard({
    super.key,
    required this.index,
    required this.player,
    required this.onRemove,
    this.handicap = 0,
    this.onHandicapChanged,
    this.handicapValues = const [],
  });

  final int index;
  final Player player;
  final VoidCallback onRemove;
  final int handicap;
  final ValueChanged<int>? onHandicapChanged;
  final List<int> handicapValues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(player.name);

    final statsAsync = ref.watch(playerStatsProvider(player.playerId));
    final avg = statsAsync.value?.threeDartAverage;
    final avgLabel = 'AVG ${StatFormatter.fmtDouble(avg)}';

    final isFirst = index == 0;
    final badgeBg = isFirst ? cs.primaryFixed : cs.surfaceContainerHighest;
    final badgeFg = isFirst ? AppColors.onPrimaryFixed : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: cs.primaryFixed.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: SizedBox(
                width: 48,
                height: 56,
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: cs.onSurfaceVariant,
                  semanticLabel: 'Drag to reorder',
                ),
              ),
            ),

            // Avatar + position badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Text(
                    initials,
                    style: tt.labelMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.space3),

            // Name + avg PPR
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    style: tt.titleMedium?.copyWith(color: cs.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    avgLabel,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            if (onHandicapChanged != null) ...[
              const SizedBox(width: AppSpacing.space1),
              _HandicapChip(
                handicap: handicap,
                onChanged: onHandicapChanged!,
                values: handicapValues,
              ),
            ],

            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.remove_circle_outline,
                color: cs.onSurfaceVariant,
                semanticLabel: 'Remove ${player.name}',
              ),
              splashColor: cs.error.withValues(alpha: 0.08),
              highlightColor: cs.error.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Handicap chip ─────────────────────────────────────────────────────────────

class _HandicapChip extends StatelessWidget {
  const _HandicapChip({
    required this.handicap,
    required this.onChanged,
    required this.values,
  });

  final int handicap;
  final ValueChanged<int> onChanged;
  final List<int> values;

  String _label(int value) {
    if (value == 0) return '0';
    return value > 0 ? '+$value' : '−${value.abs()}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = handicap != 0;

    return PopupMenuButton<int>(
      initialValue: handicap,
      onSelected: onChanged,
      tooltip: 'Set handicap',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? cs.primaryFixed : cs.outlineVariant,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          color: isActive
              ? cs.primaryFixed.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HCP',
              style: tt.labelSmall?.copyWith(
                fontSize: 9,
                color: isActive ? cs.primaryFixed : cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              _label(handicap),
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive ? cs.primaryFixed : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => values
          .map(
            (value) => PopupMenuItem<int>(
              value: value,
              child: Text(_label(value)),
            ),
          )
          .toList(),
    );
  }
}

// ── Roster grid ───────────────────────────────────────────────────────────────

class _RosterGrid extends StatelessWidget {
  const _RosterGrid({
    required this.players,
    required this.selectedIds,
    required this.maxPlayers,
    required this.onTapPlayer,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final int? maxPlayers;
  final void Function(String id) onTapPlayer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemCount = players.length;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = constraints.maxWidth / 4;
          return SizedBox(
            height: cellHeight * 2.33,
            child: GridView.builder(
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
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
    final tt = Theme.of(context).textTheme;
    final initials = _initials(name);
    final truncated = name.length > 8 ? '${name.substring(0, 7)}…' : name;

    Widget cell = InkWell(
      onTap: isDisabled ? null : onTap,
      splashColor: cs.onSurface.withValues(alpha: 0.08),
      highlightColor: cs.onSurface.withValues(alpha: 0.08),
      child: Opacity(
        opacity: (isDisabled && !isSelected) ? 0.4 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected
                      ? cs.primaryFixed.withValues(alpha: 0.15)
                      : cs.surfaceContainerHighest,
                  child: isSelected
                      ? null
                      : Text(
                          initials,
                          style: tt.labelMedium?.copyWith(color: cs.onSurface),
                        ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 40,
                    color: cs.primaryFixed.withValues(alpha: 0.60),
                    semanticLabel: 'Selected',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              truncated,
              style: tt.labelSmall?.copyWith(
                color: isDisabled && !isSelected
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
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
      // Use the core use-case provider directly: this is a one-shot create
      // with no form-state lifecycle, so going through CreatePlayerNotifier
      // would only add a cross-feature import. AllPlayers is a drift
      // `.watch()` stream — drift surfaces the insert automatically, so no
      // manual `ref.invalidate(allPlayersProvider)` here.
      final player =
          await ref.read(createPlayerUseCaseProvider).call(name);
      if (mounted) {
        widget.onPlayerCreated(player.playerId);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = e is RepositoryException ? e.message : e.toString();
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
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryFixed,
                foregroundColor: AppColors.onPrimaryFixed,
                disabledBackgroundColor:
                    cs.primaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                disabledForegroundColor:
                    AppColors.onPrimaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
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
