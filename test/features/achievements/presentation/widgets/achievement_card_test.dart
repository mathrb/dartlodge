import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_status.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:dart_lodge/features/achievements/presentation/widgets/achievement_card.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  final firstWin = kAchievements.firstWhere((a) => a.id == 'first_win'); // binary
  final darts10k = kAchievements.firstWhere((a) => a.id == 'darts_10000'); // counter

  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
      ));

  testWidgets('unlocked: filled trophy + title + unlock date', (tester) async {
    await pump(
      tester,
      AchievementCard(
        status: AchievementStatus(
            achievement: firstWin, current: 1, target: 1, unlocked: true),
        unlockedAt: DateTime(2026, 1, 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Win'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    expect(find.textContaining('Unlocked on'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('locked binary: outline trophy, no progress bar', (tester) async {
    await pump(
      tester,
      AchievementCard(
        status: AchievementStatus(
            achievement: firstWin, current: 0, target: 1, unlocked: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Win'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Unlocked on'), findsNothing);
  });

  testWidgets('locked counter: progress bar + current/target', (tester) async {
    await pump(
      tester,
      AchievementCard(
        status: AchievementStatus(
            achievement: darts10k, current: 6320, target: 10000, unlocked: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10,000 Darts'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.632, 1e-6));
    expect(find.text('6320 / 10000'), findsOneWidget);
  });
}
