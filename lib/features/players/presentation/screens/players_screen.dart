// Players Screen
// Main screen for managing players

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayersScreen extends ConsumerWidget {
  final bool showAddDialog;
  
  const PlayersScreen({super.key, this.showAddDialog = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Show add player dialog
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Players Screen - Under Construction'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add player
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}