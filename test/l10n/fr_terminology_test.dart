import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Regression for #614 (F-023/F-024/F-026): French darts terminology must be
/// consistent — "tour" for a round/turn, "leg" for an X01 leg — and the
/// advance-turn body must elide "que" + "une" idiomatically.
void main() {
  late AppLocalizations fr;

  setUp(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  test('F-023 — round breakdown uses "tour", not "manche"', () {
    expect(fr.historyRoundBreakdown, 'Détail des tours');
  });

  test('F-024 — nine-darter description uses "leg", not "manche"', () {
    expect(fr.achievementNineDarterDescription, contains('leg'));
    expect(fr.achievementNineDarterDescription, isNot(contains('manche')));
  });

  test('F-026 — advance-turn body elides: "qu\'une fléchette" for 1 dart', () {
    expect(fr.gameAdvanceTurnBody(1), contains("qu'une fléchette"));
    expect(fr.gameAdvanceTurnBody(1), isNot(contains('que 1')));
    // The plural branch stays "que N fléchettes".
    expect(fr.gameAdvanceTurnBody(2), contains('que 2 fléchettes'));
  });
}
