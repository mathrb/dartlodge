// Game Selection Screen
// Screen for selecting game types and starting new games

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameSelectionScreen extends ConsumerWidget {
  final String? gameId;
  
  const GameSelectionScreen({super.key, this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game Type'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('X01'),
            subtitle: const Text('Standard darts game (301, 501, etc.)'),
            onTap: () {
              // TODO: Navigate to X01 game setup
            },
          ),
          ListTile(
            title: const Text('Cricket'),
            subtitle: const Text('Classic cricket darts game'),
            onTap: () {
              // TODO: Navigate to Cricket game setup
            },
          ),
          ListTile(
            title: const Text('Around the Clock'),
            subtitle: const Text('Hit numbers in sequence'),
            onTap: () {
              // TODO: Navigate to Around the Clock game setup
            },
          ),
          ListTile(
            title: const Text('Killer'),
            subtitle: const Text('Eliminate opponents by hitting their numbers'),
            onTap: () {
              // TODO: Navigate to Killer game setup
            },
          ),
        ],
      ),
    );
  }
}