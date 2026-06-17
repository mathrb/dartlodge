import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/presentation/widgets/player_card_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  Player player({required DateTime lastActive}) => Player(
        playerId: 'p1',
        name: 'Alice',
        createdAt: DateTime.utc(2024, 1, 1),
        lastActive: lastActive,
      );

  Future<void> pump(WidgetTester tester, Locale locale, Player p) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        home: Scaffold(body: PlayerCardWidget(player: p)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows localized "today" when active now', (tester) async {
    await pump(tester, const Locale('en'), player(lastActive: DateTime.now()));
    expect(find.text('Last active: Today'), findsOneWidget);
  });

  testWidgets('shows the pluralized relative date (EN)', (tester) async {
    await pump(tester, const Locale('en'),
        player(lastActive: DateTime.now().subtract(const Duration(days: 2))));
    expect(find.text('Last active: 2 days ago'), findsOneWidget);
  });

  testWidgets('shows the pluralized relative date (FR)', (tester) async {
    await pump(tester, const Locale('fr'),
        player(lastActive: DateTime.now().subtract(const Duration(days: 2))));
    expect(find.text('Dernière activité : il y a 2 jours'), findsOneWidget);
  });
}
