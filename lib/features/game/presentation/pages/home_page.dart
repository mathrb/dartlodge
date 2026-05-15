import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                trailing: IconButton(
                  icon: Icon(Icons.settings, color: cs.onSurface, semanticLabel: 'Settings'),
                  tooltip: 'Settings',
                  onPressed: () => context.push(GameRoutes.settings),
                ),
              ),
              const SizedBox(height: 16),
              _KineticGameCard(
                label: 'X01',
                subtitle: '301, 501, 701',
                icon: Icons.adjust,
                onTap: () {
                  ref.read(gameSetupProvider.notifier).reset();
                  context.push('${GameRoutes.variantSelection}/x01');
                },
              ),
              const SizedBox(height: 12),
              _KineticGameCard(
                label: 'Cricket',
                subtitle: 'Strategic Play',
                icon: Icons.sports_cricket,
                onTap: () {
                  ref.read(gameSetupProvider.notifier).reset();
                  context.push('${GameRoutes.variantSelection}/cricket');
                },
              ),
              const SizedBox(height: 12),
              _KineticGameCard(
                label: 'Practice',
                subtitle: 'Improve Skills',
                icon: Icons.track_changes,
                onTap: () {
                  ref.read(gameSetupProvider.notifier).reset();
                  context.push('${GameRoutes.variantSelection}/practice');
                },
              ),
              const SizedBox(height: 24),
              _FlatNavRow(
                label: 'Statistics',
                descriptor: 'Analyze Data',
                icon: Icons.bar_chart,
                onTap: () => context.push(GameRoutes.stats),
              ),
              const SizedBox(height: 4),
              _FlatNavRow(
                label: 'History',
                descriptor: 'Sessions',
                icon: Icons.history,
                onTap: () => context.push(GameRoutes.history),
              ),
              const SizedBox(height: 4),
              _FlatNavRow(
                label: 'Players',
                descriptor: 'Roster',
                icon: Icons.group,
                onTap: () => context.push(GameRoutes.players),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────


class _KineticGameCard extends StatelessWidget {
  const _KineticGameCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.kineticCardDecoration(cs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.kineticSplashColor,
          highlightColor: AppTheme.kineticSplashColor,
          child: SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatNavRow extends StatelessWidget {
  const _FlatNavRow({
    required this.label,
    required this.descriptor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String descriptor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        splashColor: cs.onSurface.withValues(alpha: 0.06),
        highlightColor: cs.onSurface.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurface,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
              Text(
                descriptor.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
