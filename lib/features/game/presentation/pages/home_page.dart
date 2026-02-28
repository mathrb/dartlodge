import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/widgets/game_card_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Darts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              GameCardWidget(
                label: 'X01',
                color: const Color(0xFFC62828),
                icon: Icons.looks_one,
                onTap: () {
                  ref
                      .read(gameSetupProvider.notifier)
                      .selectGameType(GameType.x01);
                  context.push('/game/variant-selection/x01');
                },
              ),
              GameCardWidget(
                label: 'Cricket',
                color: const Color(0xFF00897B),
                icon: Icons.sports_cricket,
                onTap: () {
                  ref
                      .read(gameSetupProvider.notifier)
                      .selectGameType(GameType.cricket);
                  context.push('/game/variant-selection/cricket');
                },
              ),
              GameCardWidget(
                label: 'Practice',
                color: const Color(0xFFF57C00),
                icon: Icons.track_changes,
                onTap: () {
                  ref.read(gameSetupProvider.notifier).reset();
                  context.push('/game/variant-selection/practice');
                },
              ),
              GameCardWidget(
                label: 'Statistics',
                color: const Color(0xFF7B1FA2),
                icon: Icons.bar_chart,
                onTap: () => context.go('/stats'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GameCardWidget(
            label: 'Game Lobby',
            color: const Color(0xFF37474F),
            icon: Icons.people,
            onTap: null,
          ),
          const SizedBox(height: 12),
          GameCardWidget(
            label: 'VS Friends',
            color: const Color(0xFF37474F),
            icon: Icons.group,
            onTap: null,
          ),
          const SizedBox(height: 12),
          GameCardWidget(
            label: 'Bluetooth',
            color: const Color(0xFF37474F),
            icon: Icons.bluetooth,
            onTap: null,
          ),
        ],
      ),
    );
  }
}
