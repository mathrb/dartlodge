// Statistics Screen
// Main screen for viewing player and game statistics

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Player Stats'),
              Tab(text: 'Game History'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Player Statistics - Under Construction')),
            Center(child: Text('Game History - Under Construction')),
            Center(child: Text('Leaderboard - Under Construction')),
          ],
        ),
      ),
    );
  }
}