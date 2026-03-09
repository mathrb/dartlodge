import 'package:flutter/material.dart';

import 'leaderboard_page.dart';

class StatsTabPage extends StatelessWidget {
  const StatsTabPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Stats')),
        body: const LeaderboardPage(),
      );
}
