import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/presentation/widgets/player_avatar_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

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

  String _formatLastActive(BuildContext context, AppLocalizations l10n) {
    final now = DateTime.now();
    final local = player.lastActive.toLocal();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    if (diff <= 0) return l10n.playersRelativeToday;
    if (diff == 1) return l10n.playersRelativeYesterday;
    if (diff < 7) return l10n.playersRelativeDaysAgo(diff);
    return DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(local);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minTileHeight: 64,
      leading: PlayerAvatarWidget(player: player, size: 40),
      title: Text(player.name),
      subtitle:
          Text(l10n.playersCardLastActive(_formatLastActive(context, l10n))),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
