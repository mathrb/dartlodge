import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/game/presentation/widgets/variant_card_widget.dart';

class VariantSelectionPage extends ConsumerWidget {
  const VariantSelectionPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(gameSetupProvider);
    final selectedConfig = setupState.maybeMap(
      configuringGame: (s) => s.config,
      orElse: () => null,
    );

    final lastConfig = (category == 'x01' || category == 'cricket')
        ? ref.watch(lastGameConfigProvider(category)).value
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
        title: Text(_titleFor(category)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: _cardsFor(category, ref, context, selectedConfig, lastConfig),
      ),
    );
  }

  String _titleFor(String cat) => switch (cat) {
        'x01' => 'X01',
        'cricket' => 'Cricket',
        'practice' => 'Practice',
        _ => cat,
      };

  List<Widget> _cardsFor(
    String cat,
    WidgetRef ref,
    BuildContext context,
    GameConfig? selectedConfig,
    GameConfig? lastConfig,
  ) {
    final variants = switch (cat) {
      'x01' => _x01Variants(),
      'cricket' => _cricketVariants(),
      'practice' => _practiceVariants(),
      _ => <_VariantEntry>[],
    };

    final widgets = <Widget>[];

    if (lastConfig != null) {
      widgets.add(_LastUsedTile(
        config: lastConfig,
        onTap: () {
          ref.read(gameSetupProvider.notifier).selectVariant(lastConfig);
          context.push('/game/player-selection');
        },
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(const Divider(height: 1));
      widgets.add(const SizedBox(height: 8));
    }

    for (var i = 0; i < variants.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 8));
      final v = variants[i];
      widgets.add(VariantCardWidget(
        key: ValueKey(v.config),
        title: v.label,
        subtitle: v.subtitle,
        isSelected: v.config != null && v.config == selectedConfig,
        isEnabled: v.isEnabled,
        onTap: v.config == null
            ? null
            : () {
                ref.read(gameSetupProvider.notifier).selectVariant(v.config!);
                context.push('/game/player-selection');
              },
      ));
    }

    widgets.add(const SizedBox(height: 16));
    widgets.add(const _HintLine());

    return widgets;
  }

  static List<_VariantEntry> _x01Variants() => [
        const _VariantEntry(
          label: '501 — Double Out',
          subtitle: 'Double Out · 1 Leg',
          isRecommended: true,
          config: GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        const _VariantEntry(
          label: '301 — Double Out',
          subtitle: 'Double Out · 1 Leg',
          config: GameConfig.x01(
            startingScore: 301,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        const _VariantEntry(
          label: '701 — Double Out',
          subtitle: 'Double Out · 1 Leg',
          config: GameConfig.x01(
            startingScore: 701,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        const _VariantEntry(
          label: '901 — Double Out',
          subtitle: 'Double Out · 1 Leg',
          config: GameConfig.x01(
            startingScore: 901,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        const _VariantEntry(label: 'Custom', isEnabled: false),
      ];

  static List<_VariantEntry> _cricketVariants() => [
        _VariantEntry(
          label: 'Standard',
          subtitle: 'Close 15–20 & Bull · Standard',
          config: GameConfig.cricket(
            variant: 'standard',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'No Score',
          subtitle: 'Close only · No points',
          config: GameConfig.cricket(
            variant: 'no-score',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'Cut Throat',
          subtitle: 'Cut-Throat · Score on opponent',
          config: GameConfig.cricket(
            variant: 'cut-throat',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'Tactics',
          subtitle: 'Strategy variant · No points',
          config: GameConfig.cricket(
            variant: 'tactics',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        const _VariantEntry(label: 'Custom', isEnabled: false),
      ];

  static List<_VariantEntry> _practiceVariants() => [
        const _VariantEntry(
          label: 'Around the Clock',
          config: GameConfig.aroundTheClock(),
        ),
        const _VariantEntry(
          label: 'Catch 40',
          config: GameConfig.catch40(),
        ),
        const _VariantEntry(
          label: "Bob's 27",
          config: GameConfig.bobs27(),
        ),
        const _VariantEntry(
          label: 'Shanghai',
          subtitle: '7 Rounds',
          config: GameConfig.shanghai(),
        ),
        const _VariantEntry(
          label: '170 Checkout',
          config: GameConfig.checkoutPractice(),
        ),
      ];
}

class _LastUsedTile extends StatelessWidget {
  const _LastUsedTile({required this.config, required this.onTap});

  final GameConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: cs.secondary, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.history, color: cs.onSecondaryContainer, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Used',
                    style: tt.bodyLarge?.copyWith(color: cs.onSecondaryContainer),
                  ),
                  Text(
                    _summary,
                    style: tt.bodySmall?.copyWith(color: cs.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _summary => config.maybeMap(
        x01: (c) {
          final inLabel = switch (c.inStrategy) {
            'double' => 'Double',
            'master' => 'Master',
            _ => 'Straight',
          };
          final outLabel = switch (c.outStrategy) {
            'double' => 'Double',
            'master' => 'Master',
            _ => 'Straight',
          };
          final legs = c.legsToWin == 1 ? '1 Leg' : 'Bo${c.legsToWin}';
          return '${c.startingScore} · $inLabel In · $outLabel Out · $legs';
        },
        cricket: (c) {
          final variant = switch (c.variant) {
            'cut-throat' => 'Cut Throat',
            'no-score' => 'No Score',
            'tactics' => 'Tactics',
            _ => 'Standard',
          };
          return '$variant · ${c.numbers.length} numbers';
        },
        orElse: () => '',
      );
}

class _HintLine extends StatelessWidget {
  const _HintLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Select a preset — you can adjust the settings on the next screen',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _VariantEntry {
  const _VariantEntry({
    required this.label,
    this.subtitle,
    this.config,
    this.isRecommended = false,
    this.isEnabled = true,
  });

  final String label;
  final String? subtitle;
  final GameConfig? config;
  final bool isRecommended;
  final bool isEnabled;
}
