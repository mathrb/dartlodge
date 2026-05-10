import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/statistics_provider.dart';
import '../widgets/game_summary_section_widget.dart';

class PostGameSummaryPage extends ConsumerWidget {
  const PostGameSummaryPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(gameStatsProvider(gameId));

    return Scaffold(
      body: SafeArea(
        child: asyncStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (gameStats) => Stack(
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
                        onPressed: () => context.push(GameRoutes.settings),
                      ),
                    ),
                    GameSummarySectionWidget(gameStats: gameStats),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sticky Footer ─────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  const _StickyFooter();

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
                  onTap: () => context.go('/'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FooterButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.refresh,
                  isPrimary: true,
                  onTap: () => context.go('/game-setup'),
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
