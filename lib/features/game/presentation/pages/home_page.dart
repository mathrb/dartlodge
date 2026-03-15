import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
import 'package:my_darts/core/utils/app_colors.dart';
import 'package:my_darts/core/utils/app_theme.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Darts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go(GameRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            const _SectionLabel(label: 'PLAY'),
            const SizedBox(height: 8),
            _PlayCard(
              label: 'X01',
              accentColor: AppColors.primary,
              onTap: () {
                ref.read(gameSetupProvider.notifier).reset();
                context.go('${GameRoutes.variantSelection}/x01');
              },
            ),
            const SizedBox(height: 8),
            _PlayCard(
              label: 'Cricket',
              accentColor: AppColors.secondary,
              onTap: () {
                ref.read(gameSetupProvider.notifier).reset();
                context.go('${GameRoutes.variantSelection}/cricket');
              },
            ),
            const SizedBox(height: 8),
            _PlayCard(
              label: 'Practice',
              accentColor: AppColors.onPrimaryContainer,
              onTap: () {
                ref.read(gameSetupProvider.notifier).reset();
                context.go('${GameRoutes.variantSelection}/practice');
              },
            ),
            const SizedBox(height: 8),
            _PlayCard(
              label: 'Statistics',
              accentColor: AppColors.secondary,
              onTap: () => context.go(GameRoutes.stats),
            ),
            const SizedBox(height: 16),
            _NavCard(
              label: 'History',
              onTap: () => context.go(GameRoutes.history),
            ),
            const SizedBox(height: 12),
            _NavCard(
              label: 'Local Players',
              onTap: () => context.go(GameRoutes.players),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'COMING SOON'),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.6,
              child: Column(
                children: const [
                  _ComingSoonCard(label: 'Game Lobby'),
                  SizedBox(height: 12),
                  _ComingSoonCard(label: 'VS Friends'),
                ],
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: AppColors.onSurfaceVariant),
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppTheme.radiusLarge));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accentColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppColors.onBackground),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accentColor),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusLarge)),
        side: BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppTheme.radiusLarge)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.onBackground),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Coming soon',
      child: MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: Card(
          color: AppColors.surfaceVariant,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppTheme.radiusLarge)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
