import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/presentation/widgets/player_avatar_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/relative_date.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PlayerCardWidget({
    super.key,
    required this.player,
    this.onTap,
    this.trailing,
  });

  String _formatLastActive(BuildContext context) {
    return relativeDayLabel(context, player.lastActive) ??
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(player.lastActive.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minTileHeight: 64,
      leading: PlayerAvatarWidget(player: player, size: 40),
      title: Text(player.name),
      subtitle: Text(l10n.playersCardLastActive(_formatLastActive(context))),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
