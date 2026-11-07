import 'package:flutter/widgets.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../domain/models/game_state.dart';

/// The per-player legs-won readout on the X01 / Cricket boards (e.g.
/// `'LEGS 1'`), so the match score is visible during a multi-leg match.
///
/// Returns null for a single-leg game (`legsToWin == 1`), where the tally is
/// always 0 and only adds noise; callers hide the readout on null.
String? legsWonLabel(
  BuildContext context,
  GameState gameState,
  CompetitorState competitor,
) {
  if (gameState.legsToWin <= 1) return null;
  return AppLocalizations.of(
    context,
  ).gameLegsWon(StatFormatter.fmtInt(competitor.legsWon));
}
