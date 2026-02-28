import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/widgets/variant_pill_widget.dart';

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
      appBar: AppBar(title: Text(_titleFor(category))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _pillsFor(category, ref, context, selectedConfig),
      ),
    );
  }

  String _titleFor(String cat) => switch (cat) {
        'x01' => 'X01',
        'cricket' => 'Cricket',
        'practice' => 'Practice',
        _ => cat,
      };

  List<Widget> _pillsFor(
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
      widgets.add(VariantPillWidget(
        label: v.label,
        isRecommended: v.isRecommended,
        isEnabled: v.isEnabled,
        isSelected: v.config != null && v.config == selectedConfig,
        onTap: v.config == null
            ? null
            : () {
                ref.read(gameSetupProvider.notifier).selectVariant(v.config!);
                context.push('/game/player-selection');
              },
      ));
    }
    return widgets;
  }

  static List<_VariantEntry> _x01Variants() => [
        _VariantEntry(
          label: '301',
          config: const GameConfig.x01(
            startingScore: 301,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '501',
          isRecommended: true,
          config: const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '701',
          config: const GameConfig.x01(
            startingScore: 701,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '901',
          config: const GameConfig.x01(
            startingScore: 901,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(label: 'Custom', isEnabled: false),
      ];

  static List<_VariantEntry> _cricketVariants() => [
        _VariantEntry(
          label: 'Standard',
          config: GameConfig.cricket(
            variant: 'standard',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'No Score',
          config: GameConfig.cricket(
            variant: 'no-score',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'Cut Throat',
          config: GameConfig.cricket(
            variant: 'cut-throat',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(
          label: 'Tactics',
          config: GameConfig.cricket(
            variant: 'tactics',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        ),
        _VariantEntry(label: 'Custom', isEnabled: false),
      ];

  static List<_VariantEntry> _practiceVariants() => [
        _VariantEntry(
          label: 'Around the Clock',
          config: const GameConfig.aroundTheClock(),
        ),
        _VariantEntry(
          label: 'Catch 40',
          config: const GameConfig.halveIt(),
        ),
        _VariantEntry(
          label: "Bob's 27",
          config: const GameConfig.scram(),
        ),
        _VariantEntry(
          label: 'Shanghai',
          config: const GameConfig.shanghai(),
        ),
        _VariantEntry(
          label: '170 Checkout',
          config: const GameConfig.chaseTheDragon(),
        ),
      ];
}

class _VariantEntry {
  const _VariantEntry({
    required this.label,
    this.config,
    this.isRecommended = false,
    this.isEnabled = true,
  });

  final String label;
  final GameConfig? config;
  final bool isRecommended;
  final bool isEnabled;
}
