import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/utils/app_colors.dart';
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
            onPressed: () => context.go('/settings'),
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.outline),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Column(
                  children: [
                    _PlayRow(
                      label: 'X01',
                      accentColor: AppColors.primary,
                      onTap: () => context.go('/game/variant-selection/x01'),
                    ),
                    Divider(height: 1, thickness: 1, color: AppColors.outline),
                    _PlayRow(
                      label: 'Cricket',
                      accentColor: AppColors.secondary,
                      onTap: () =>
                          context.go('/game/variant-selection/cricket'),
                    ),
                    Divider(height: 1, thickness: 1, color: AppColors.outline),
                    _PlayRow(
                      label: 'Practice',
                      accentColor: AppColors.onPrimaryContainer,
                      onTap: () {
                        ref.read(gameSetupProvider.notifier).reset();
                        context.go('/game/variant-selection/practice');
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: AppColors.outline),
                    _PlayRow(
                      label: 'Statistics',
                      accentColor: AppColors.secondary,
                      onTap: () => context.go('/stats'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _NavCard(
              label: 'History',
              onTap: () => context.go('/history'),
            ),
            const SizedBox(height: 12),
            _NavCard(
              label: 'Local Players',
              onTap: () => context.go('/players'),
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

class _PlayRow extends StatelessWidget {
  const _PlayRow({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
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
            borderRadius: BorderRadius.all(Radius.circular(16)),
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
