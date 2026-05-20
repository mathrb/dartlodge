import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_header.dart';
import 'package:dart_lodge/core/providers/statistics_providers.dart';
import '../../../../core/widgets/game_summary_section_widget.dart';
import '../../../game/domain/models/game_result.dart';
import '../widgets/practice_summary_widget.dart';
import '../widgets/shanghai_summary_widget.dart';

/// Maps a game type name (e.g. `GameType.x01.name`) to the variant-selection
/// category route segment used by `/game/variant-selection/:category`.
///
/// Categories: `x01`, `cricket`, `casual` (shanghai, count-up), `practice`
/// (around-the-clock, catch40, bobs27, checkoutPractice). Drives the
/// PLAY AGAIN button's replay-category target.
@visibleForTesting
String categoryForGameType(String gameTypeName) {
  if (gameTypeName == GameType.x01.name) return 'x01';
  if (gameTypeName == GameType.cricket.name) return 'cricket';
  if (gameTypeName == GameType.shanghai.name ||
      gameTypeName == GameType.countUp.name) {
    return 'casual';
  }
  return 'practice';
}

/// Game types whose post-game summary still consumes `gameStatsProvider`
/// (x01-shaped chrome via [GameSummarySectionWidget]). All other types go
/// through `gameResultProvider` to render their per-type summary.
final _gameStatsBackedTypes = <String>{
  GameType.x01.name,
  GameType.cricket.name,
  GameType.countUp.name,
};

class PostGameSummaryPage extends ConsumerWidget {
  const PostGameSummaryPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(gameStatsProvider(gameId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(GameRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: asyncStats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (gameStats) {
              final usesGameStats =
                  _gameStatsBackedTypes.contains(gameStats.gameType);
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeader(
                          showBack: true,
                          onBack: () => context.go('/'),
                          trailing: IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                semanticLabel: 'Settings'),
                            onPressed: () =>
                                context.push(GameRoutes.settings),
                          ),
                        ),
                        if (usesGameStats)
                          GameSummarySectionWidget(gameStats: gameStats)
                        else
                          _GameResultBody(gameId: gameId),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _StickyFooter(
                      playAgainCategory:
                          categoryForGameType(gameStats.gameType),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameResultBody extends ConsumerWidget {
  const _GameResultBody({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(gameResultProvider(gameId));
    return asyncResult.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text('Error: $err'),
      ),
      data: (result) {
        if (result == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('No result available for this game.'),
          );
        }
        return switch (result) {
          ShanghaiResult() => ShanghaiSummaryWidget(result: result),
          _ => PracticeSummaryWidget(result: result),
        };
      },
    );
  }
}

// ── Sticky Footer ─────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.playAgainCategory});

  final String playAgainCategory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: cs.surfaceContainer
                    .withValues(alpha: AppTheme.opacityBottomBarTopEdge),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: _FooterButton(
                  label: 'DONE',
                  icon: Icons.check_circle_outline,
                  isPrimary: false,
                  onTap: () => context.go(GameRoutes.home),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FooterButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.refresh,
                  isPrimary: true,
                  onTap: () => context.go(
                    '${GameRoutes.variantSelection}/$playAgainCategory',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = isPrimary ? cs.primaryFixed : cs.surfaceContainerHighest;
    final fgColor = isPrimary ? cs.onPrimaryFixed : cs.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: isPrimary
                ? null
                : Border.all(
                    color: cs.outlineVariant.withValues(
                        alpha: AppTheme.opacityGhostBorderStrong),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fgColor, size: 20, semanticLabel: label),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
