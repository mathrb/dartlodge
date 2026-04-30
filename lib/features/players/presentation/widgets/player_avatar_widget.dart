import 'package:flutter/material.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final double size;

  const PlayerAvatarWidget({super.key, required this.player, this.size = 40});

  static const List<Color> _colors = [
    Color(0xFF1976D2), // blue
    Color(0xFF388E3C), // green
    Color(0xFFF57C00), // orange
    Color(0xFF7B1FA2), // purple
    Color(0xFFC62828), // red
    Color(0xFF00838F), // cyan
    Color(0xFF558B2F), // light green
    Color(0xFF6D4C41), // brown
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[player.playerId.hashCode.abs() % _colors.length];
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.45, color: Colors.white),
      ),
    );
  }
}
