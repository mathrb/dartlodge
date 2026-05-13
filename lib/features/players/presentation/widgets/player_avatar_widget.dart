import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

/// Round avatar showing a player's first initial on a stable identity color.
///
/// Hue is picked from the design system's identity palette
/// (`AppColors.avatarPalette`) — a formalized exception to the
/// no-hardcoded-colors rule. See `docs/design/DESIGN_SYSTEM.md` §2.7.
class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final double size;

  const PlayerAvatarWidget({super.key, required this.player, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    final color = palette[player.playerId.hashCode.abs() % palette.length];
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.45, color: AppColors.onAvatar),
      ),
    );
  }
}
