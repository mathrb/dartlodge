import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/core/widgets/heatmap_dartboard_widget.dart';
import 'package:dart_lodge/core/widgets/heatmap_density.dart' show HeatPoint;
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

import '../../domain/entities/dart_position.dart';
import '../../domain/entities/game_stats.dart';
import '../providers/dart_heatmap_provider.dart';

/// Post-game impact heatmap, one dartboard per competitor.
///
/// SI-6 (#577) of the heatmap epic (#571). Lives in the **statistics feature**
/// — not in `core/widgets/GameSummarySectionWidget` — because it must import
/// both `HeatmapDartboardWidget` (core) and `dartHeatmapProvider` (a statistics
/// provider). A `core/` widget cannot import a feature provider (core→feature
/// is a forbidden dependency direction), so the integration happens one layer
/// up, where importing both is allowed. The post-game page composes this
/// directly after the core summary section.
///
/// The whole section is hidden when the game has NO located darts for any
/// competitor (e.g. a fully-manual game) — the data providers all resolve to
/// an empty list. A per-competitor selector switches which player's impacts
/// are shown; each selection drives a distinct
/// `dartHeatmapProvider(DartHeatmapFilter(gameId, playerId))` request.
class GameHeatmapSectionWidget extends ConsumerStatefulWidget {
  const GameHeatmapSectionWidget({required this.gameStats, super.key});

  final GameStats gameStats;

  @override
  ConsumerState<GameHeatmapSectionWidget> createState() =>
      _GameHeatmapSectionWidgetState();
}

/// A competitor that has at least one resolvable player id, paired with the
/// player id the heatmap query is scoped to. Team competitors map to their
/// first player (darts is effectively one player per competitor).
class _HeatmapCompetitor {
  const _HeatmapCompetitor({
    required this.name,
    required this.playerId,
    required this.totalDartsThrown,
  });

  final String name;
  final String playerId;
  final int totalDartsThrown;
}

class _GameHeatmapSectionWidgetState
    extends ConsumerState<GameHeatmapSectionWidget> {
  int _selectedIndex = 0;

  List<_HeatmapCompetitor> _competitors() {
    final result = <_HeatmapCompetitor>[];
    for (final c in widget.gameStats.byCompetitor) {
      if (c.byPlayer.isEmpty) continue;
      result.add(
        _HeatmapCompetitor(
          name: c.competitorName,
          playerId: c.byPlayer.first.playerId,
          totalDartsThrown: c.totalDartsThrown,
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final competitors = _competitors();

    if (competitors.isEmpty) return const SizedBox.shrink();

    // Watch every competitor's positions so we can hide the entire section
    // when the game has no located darts at all. Until all have resolved we
    // optimistically show the section (a loader renders for the selected one).
    final positionsByCompetitor = <AsyncValue<List<DartPosition>>>[
      for (final c in competitors)
        ref.watch(
          dartHeatmapProvider(
            DartHeatmapFilter(gameId: widget.gameStats.gameId, playerId: c.playerId),
          ),
        ),
    ];

    final allResolved =
        positionsByCompetitor.every((p) => p.hasValue || p.hasError);
    final anyLocated = positionsByCompetitor
        .any((p) => (p.value ?? const <DartPosition>[]).isNotEmpty);

    // Fully manual game (or every player un-located) → nothing to show.
    if (allResolved && !anyLocated) return const SizedBox.shrink();

    final selectedIndex =
        _selectedIndex.clamp(0, competitors.length - 1).toInt();
    final selected = competitors[selectedIndex];
    final selectedPositions = positionsByCompetitor[selectedIndex];

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsHeatmapTitle.toUpperCase(),
            style: AppTextStyles.labelLarge.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (competitors.length > 1)
            _PlayerSelector(
              names: [for (final c in competitors) c.name],
              selectedIndex: selectedIndex,
              onSelected: (i) => setState(() => _selectedIndex = i),
            ),
          if (competitors.length > 1) const SizedBox(height: 12),
          _HeatmapBody(
            positions: selectedPositions,
            totalDartsThrown: selected.totalDartsThrown,
          ),
        ],
      ),
    );
  }
}

/// Segmented control over the game's competitors. Matches the house style of
/// [TimeRangeSelectorWidget].
class _PlayerSelector extends StatelessWidget {
  const _PlayerSelector({
    required this.names,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> names;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: [
            for (var i = 0; i < names.length; i++)
              ButtonSegment(value: i, label: Text(names[i])),
          ],
          selected: {selectedIndex},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onSelected(s.first),
        ),
      ),
    );
  }
}

/// Renders the selected player's heatmap, handling all three async states and
/// an optional "N un-located darts" note for mixed (auto + manual) games.
class _HeatmapBody extends StatelessWidget {
  const _HeatmapBody({
    required this.positions,
    required this.totalDartsThrown,
  });

  final AsyncValue<List<DartPosition>> positions;
  final int totalDartsThrown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return positions.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.statsLoadFailed(err.toString()),
          style: AppTextStyles.bodySmall.copyWith(color: cs.error),
        ),
      ),
      data: (located) {
        if (located.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.statsHeatmapNoData,
              style: AppTextStyles.bodySmall
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        final points = <HeatPoint>[
          for (final p in located) (x: p.x, y: p.y),
        ];
        final unlocated = totalDartsThrown - located.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: HeatmapDartboardWidget(points: points),
              ),
            ),
            if (unlocated > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.statsHeatmapUnlocated(unlocated),
                style: AppTextStyles.bodySmall
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        );
      },
    );
  }
}
