import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';

import 'leaderboard_page.dart';

class StatsTabPage extends StatelessWidget {
  const StatsTabPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
          title: const Text('Stats'),
        ),
        body: const LeaderboardPage(),
      );
}
