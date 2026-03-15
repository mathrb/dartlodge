import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
        title: Text(_titleFor(category)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: _cardsFor(category, ref, context, selectedConfig),
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
  ) {
    final variants = switch (cat) {
      'x01' => _x01Variants(),
      'cricket' => _cricketVariants(),
      'practice' => _practiceVariants(),
      _ => <_VariantEntry>[],
    };

    final widgets = <Widget>[];
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
