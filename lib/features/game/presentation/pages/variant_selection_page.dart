import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/app_text_styles.dart';
import 'package:my_darts/core/utils/app_theme.dart';
import 'package:my_darts/core/widgets/app_header.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';

class VariantSelectionPage extends ConsumerWidget {
  const VariantSelectionPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final setupState = ref.watch(gameSetupProvider);
    final selectedConfig = setupState.maybeMap(
      configuringGame: (s) => s.config,
      orElse: () => null,
    );

    final lastConfig = (category == 'x01' || category == 'cricket')
        ? ref.watch(lastGameConfigProvider(category)).value
        : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
        cacheExtent: 5000,
        children: [
          AppHeader(
            showBack: true,
            onBack: () => context.go(GameRoutes.home),
            trailing: IconButton(
              icon: Icon(Icons.settings, color: cs.onSurface, semanticLabel: 'Settings'),
              tooltip: 'Settings',
              onPressed: () => context.go(GameRoutes.settings),
            ),
          ),
          _PageHeader(category: category),
          const SizedBox(height: 24),
          if (lastConfig != null) ...[
            _LastPlayedCard(
              config: lastConfig,
              onTap: () {
                ref.read(gameSetupProvider.notifier).selectVariant(lastConfig);
                context.push('/game/player-selection');
              },
            ),
            const SizedBox(height: 16),
          ],
          ..._variantRows(context, ref, selectedConfig),
        ],
        ),
      ),
    );
  }

  List<Widget> _variantRows(BuildContext context, WidgetRef ref, GameConfig? selectedConfig) {
    final variants = switch (category) {
      'x01' => _x01Variants(),
      'cricket' => _cricketVariants(),
      'practice' => _practiceVariants(),
      _ => <_VariantEntry>[],
    };

    final rows = <Widget>[];
    for (var i = 0; i < variants.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      final v = variants[i];
      rows.add(_VariantRow(
        title: v.label,
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
    return rows;
  }

  static List<_VariantEntry> _x01Variants() => const [
        _VariantEntry(
          label: '501',
          config: GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '301',
          config: GameConfig.x01(
            startingScore: 301,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '701',
          config: GameConfig.x01(
            startingScore: 701,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '901',
          config: GameConfig.x01(
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
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'No Score',
          config: GameConfig.cricket(
            variant: 'no-score',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'Cut Throat',
          config: GameConfig.cricket(
            variant: 'cut-throat',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'Tactics',
          config: GameConfig.cricket(
            variant: 'tactics',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        const _VariantEntry(label: 'Custom', isEnabled: false),
      ];

  static List<_VariantEntry> _practiceVariants() => const [
        _VariantEntry(
          label: 'Around the Clock',
          config: GameConfig.aroundTheClock(),
        ),
        _VariantEntry(
          label: 'Catch 40',
          config: GameConfig.catch40(),
        ),
        _VariantEntry(
          label: "Bob's 27",
          config: GameConfig.bobs27(),
        ),
        _VariantEntry(
          label: 'Shanghai',
          config: GameConfig.shanghai(),
        ),
        _VariantEntry(
          label: '170 Checkout',
          config: GameConfig.checkoutPractice(),
        ),
      ];
}

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.category});

  final String category;

  String get _title => switch (category) {
        'x01' => 'X01',
        'cricket' => 'Cricket',
        'practice' => 'Practice',
        _ => category,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            'GAME SELECTION',
            style: AppTextStyles.labelSmall.copyWith(
              color: cs.onSecondaryContainer,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _title.toUpperCase(),
          style: AppTextStyles.scoreLarge(context).copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -2.0,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your match variation to begin',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Latest played card ────────────────────────────────────────────────────────

class _LastPlayedCard extends StatelessWidget {
  const _LastPlayedCard({required this.config, required this.onTap});

  final GameConfig config;
  final VoidCallback onTap;

  static BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x66232629),
            cs.primaryFixed.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: cs.primaryFixed.withValues(alpha: 0.20),
          width: 1,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: _cardDecoration(cs),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Semantics(
                  excludeSemantics: true,
                  child: Icon(
                    Icons.adjust,
                    size: 120,
                    color: cs.primaryFixed.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✦ LATEST PLAYED',
                    style: AppTextStyles.labelSmall.copyWith(color: cs.primaryFixed),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayTitle,
                    style: AppTextStyles.scoreSmall(context).copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  _MetadataRow(config: config),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _displayTitle => config.maybeMap(
        x01: (c) => '${c.startingScore}',
        cricket: (c) => switch (c.variant) {
          'cut-throat' => 'Cut Throat',
          'no-score' => 'No Score',
          'tactics' => 'Tactics',
          _ => 'Standard',
        },
        orElse: () => '',
      );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.config});

  final GameConfig config;

  @override
  Widget build(BuildContext context) {
    final chips = config.maybeMap(
      x01: (c) => [
        _MetaChip(label: 'IN', value: _strategyLabel(c.inStrategy)),
        const SizedBox(width: 16),
        _MetaChip(label: 'OUT', value: _strategyLabel(c.outStrategy)),
        const SizedBox(width: 16),
        _MetaChip(
          label: 'LEGS',
          value: c.legsToWin == 1 ? '1' : 'Bo${c.legsToWin}',
        ),
      ],
      cricket: (c) => [
        _MetaChip(
          label: 'LEGS',
          value: c.legsToWin == 1 ? '1' : 'Bo${c.legsToWin}',
        ),
        if (c.totalRounds != null) ...[
          const SizedBox(width: 16),
          _MetaChip(label: 'MAX ROUNDS', value: '${c.totalRounds}'),
        ],
      ],
      orElse: () => <Widget>[],
    );
    return Row(children: chips);
  }

  static String _strategyLabel(String strategy) => switch (strategy) {
        'double' => 'Double',
        'master' => 'Master',
        _ => 'Straight',
      };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}

// ── Variant row ───────────────────────────────────────────────────────────────

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.title,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
  });

  final String title;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row = Semantics(
      label: title,
      button: true,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          splashColor: AppTheme.kineticSplashColor,
          highlightColor: AppTheme.kineticSplashColor,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: isSelected
                ? AppTheme.kineticCardDecoration().copyWith(
                    border: Border(
                      left: BorderSide(color: cs.primaryFixed, width: 4),
                    ),
                  )
                : AppTheme.kineticCardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.scoreMedium(context).copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.4,
                      color: isSelected ? cs.primaryFixed : cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                  semanticLabel: 'Select $title',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isEnabled) row = Opacity(opacity: 0.38, child: row);

    if (!isEnabled) {
      row = Tooltip(
        message: 'Custom configuration coming soon',
        child: row,
      );
    }

    return row;
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _VariantEntry {
  const _VariantEntry({
    required this.label,
    this.config,
    this.isEnabled = true,
  });

  final String label;
  final GameConfig? config;
  final bool isEnabled;
}
