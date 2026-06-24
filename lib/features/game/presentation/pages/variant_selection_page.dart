import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/rules/rules_bottom_sheet.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';

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

    // PopScope handles Android hardware back uniformly: in the normal flow
    // the page is reached via `push` from home, so pop returns to home; on
    // deep-link entry the stack is empty, so `canPop()` is false and we
    // fall back to `go(home)` to prevent Android back from exiting the app
    // (the CLAUDE.md "If a screen MUST be reached via go(), wrap its body
    // in PopScope" guidance, generalised to also cover the push flow).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(GameRoutes.home);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
            cacheExtent: 5000,
            children: [
              AppHeader(
                showBack: true,
                // Defer to PopScope's logic so visual and hardware back
                // behave identically.
                onBack: () => Navigator.of(context).maybePop(),
                trailing: IconButton(
                  icon: Icon(Icons.settings,
                      color: cs.onSurface,
                      semanticLabel: AppLocalizations.of(context).settingsTitle),
                  tooltip: AppLocalizations.of(context).settingsTitle,
                  onPressed: () => context.push(GameRoutes.settings),
                ),
              ),
              _PageHeader(category: category),
              const SizedBox(height: 24),
              if (lastConfig != null) ...[
                _LastPlayedCard(
                  config: lastConfig,
                  onTap: () {
                    ref
                        .read(gameSetupProvider.notifier)
                        .selectVariant(lastConfig);
                    context.push(GameRoutes.playerSelection);
                  },
                ),
                const SizedBox(height: 16),
              ],
              ..._variantRows(context, ref, selectedConfig),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _variantRows(BuildContext context, WidgetRef ref, GameConfig? selectedConfig) {
    final variants = switch (category) {
      'x01' => _x01Variants(),
      'cricket' => _cricketVariants(),
      'casual' => _casualVariants(),
      'practice' => _practiceVariants(),
      _ => <_VariantEntry>[],
    };

    final rows = <Widget>[];
    for (var i = 0; i < variants.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      final v = variants[i];
      rows.add(_VariantRow(
        title: v.label,
        rulesSlug: v.rulesSlug,
        isSelected: v.config != null && v.config == selectedConfig,
        onTap: v.config == null
            ? null
            : () {
                ref.read(gameSetupProvider.notifier).selectVariant(v.config!);
                context.push(GameRoutes.playerSelection);
              },
      ));
    }
    return rows;
  }

  static List<_VariantEntry> _x01Variants() => const [
        _VariantEntry(
          label: '501',
          rulesSlug: 'x01-501',
          config: GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '301',
          rulesSlug: 'x01-301',
          config: GameConfig.x01(
            startingScore: 301,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '701',
          rulesSlug: 'x01-701',
          config: GameConfig.x01(
            startingScore: 701,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: '901',
          rulesSlug: 'x01-901',
          config: GameConfig.x01(
            startingScore: 901,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        ),
      ];

  static List<_VariantEntry> _cricketVariants() => [
        _VariantEntry(
          label: 'Standard',
          rulesSlug: 'cricket-standard',
          config: GameConfig.cricket(
            scoring: 'standard',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'No Score',
          rulesSlug: 'cricket-no-score',
          config: GameConfig.cricket(
            scoring: 'no-score',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'Cut Throat',
          rulesSlug: 'cricket-cut-throat',
          config: GameConfig.cricket(
            scoring: 'cut-throat',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'Random',
          rulesSlug: 'cricket-random',
          config: GameConfig.cricket(
            scoring: 'standard',
            targetMode: 'random',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
        _VariantEntry(
          label: 'Crazy',
          rulesSlug: 'cricket-crazy',
          config: GameConfig.cricket(
            scoring: 'standard',
            targetMode: 'crazy',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        ),
      ];

  static List<_VariantEntry> _casualVariants() => const [
        _VariantEntry(
          label: 'Shanghai',
          rulesSlug: 'practice-shanghai',
          config: GameConfig.shanghai(),
        ),
        _VariantEntry(
          label: 'Count-Up',
          rulesSlug: 'practice-count-up',
          config: GameConfig.countUp(
            totalRounds: GameConfigurationConstants.countUpDefaultRounds,
          ),
        ),
      ];

  static List<_VariantEntry> _practiceVariants() => const [
        _VariantEntry(
          label: 'Around the Clock',
          rulesSlug: 'practice-atc',
          config: GameConfig.aroundTheClock(),
        ),
        _VariantEntry(
          label: 'Catch 40',
          rulesSlug: 'practice-catch40',
          config: GameConfig.catch40(),
        ),
        _VariantEntry(
          label: "Bob's 27",
          rulesSlug: 'practice-bobs27',
          config: GameConfig.bobs27(),
        ),
        _VariantEntry(
          label: 'Checkout',
          rulesSlug: 'practice-170-checkout',
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
        'casual' => 'Casual',
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
            AppLocalizations.of(context).setupGameSelection,
            style: AppTextStyles.labelSmall.copyWith(
              color: cs.onSecondaryContainer,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _title.toUpperCase(),
          style: AppTextStyles.scoreLarge.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -2.0,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).setupSelectVariantHint,
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
            cs.surfaceContainerHigh.withValues(alpha: 0.40),
            cs.primaryFixed.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: cs.primaryFixed.withValues(alpha: AppTheme.opacityGhostBorderStrong),
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
                    AppLocalizations.of(context).setupLatestPlayed,
                    style: AppTextStyles.labelSmall.copyWith(color: cs.primaryFixed),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayTitle,
                    style: AppTextStyles.scoreSmall.copyWith(color: cs.onSurface),
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
        cricket: (c) {
          final scoringLabel = switch (c.scoring) {
            'cut-throat' => 'Cut Throat',
            'no-score' => 'No Score',
            _ => 'Standard',
          };
          final modeLabel = switch (c.targetMode) {
            'random' => 'Random',
            'crazy' => 'Crazy',
            _ => null,
          };
          // Random/Crazy default to standard scoring — show just the mode
          // label unless the user explicitly picked a non-standard scoring
          // axis, in which case `Mode · Scoring` is shown together.
          if (modeLabel != null && c.scoring == 'standard') return modeLabel;
          return modeLabel == null ? scoringLabel : '$modeLabel · $scoringLabel';
        },
        orElse: () => '',
      );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.config});

  final GameConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = config.maybeMap(
      x01: (c) => [
        _MetaChip(label: l10n.setupChipIn, value: _strategyLabel(c.inStrategy)),
        const SizedBox(width: 16),
        _MetaChip(label: l10n.setupChipOut, value: _strategyLabel(c.outStrategy)),
        const SizedBox(width: 16),
        _MetaChip(
          label: l10n.setupChipLegs,
          value: c.legsToWin == 1 ? '1' : 'Bo${c.legsToWin}',
        ),
        if (c.totalRounds != null) ...[
          const SizedBox(width: 16),
          _MetaChip(label: l10n.setupSectionRounds, value: '${c.totalRounds}'),
        ],
      ],
      cricket: (c) => [
        _MetaChip(
          label: l10n.setupSectionRounds,
          value: c.totalRounds == null ? '∞' : '${c.totalRounds}',
        ),
        const SizedBox(width: 16),
        _MetaChip(
          label: l10n.setupChipLegs,
          value: c.legsToWin == 1 ? '1' : 'Bo${c.legsToWin}',
        ),
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
    this.rulesSlug,
    this.isSelected = false,
    this.onTap,
  });

  final String title;
  final String? rulesSlug;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final row = Semantics(
      label: title,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.kineticSplashColor,
          highlightColor: AppTheme.kineticSplashColor,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: isSelected
                ? AppTheme.kineticCardDecoration(cs).copyWith(
                    border: Border(
                      left: BorderSide(color: cs.primaryFixed, width: 4),
                    ),
                  )
                : AppTheme.kineticCardDecoration(cs),
            padding: const EdgeInsets.fromLTRB(32, 20, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.scoreMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.4,
                      color: isSelected ? cs.primaryFixed : cs.onSurface,
                    ),
                  ),
                ),
                if (rulesSlug != null)
                  IconButton(
                    icon: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                    tooltip: l10n.setupHowToPlay(title),
                    onPressed: () => showRules(context, rulesSlug!),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                  semanticLabel: l10n.setupSelectVariant(title),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return row;
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _VariantEntry {
  const _VariantEntry({
    required this.label,
    this.config,
    this.rulesSlug,
  });

  final String label;
  final GameConfig? config;
  final String? rulesSlug;
}
