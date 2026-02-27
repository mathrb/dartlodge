import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_darts/features/players/presentation/pages/player_list_page.dart';

class PlayersScreen extends ConsumerWidget {
  final bool showAddDialog;

  const PlayersScreen({super.key, this.showAddDialog = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PlayerListPage();
  }
}
