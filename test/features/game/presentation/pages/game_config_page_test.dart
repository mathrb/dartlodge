// Widget tests for GameConfigPanel — focused on per-game-type fields.
// Around the Clock variant selector (#257) is the headline coverage here:
// the panel rendered an empty body for ATC before this PR.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/pages/game_config_page.dart';

Future<GameConfig?> _openPanel(
  WidgetTester tester, {
  required GameConfig initial,
}) async {
  GameConfig? returned;
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              returned = await showModalBottomSheet<GameConfig>(
                context: context,
                isScrollControlled: true,
                builder: (_) => GameConfigPanel(initialConfig: initial),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Wait for the panel to fully build.
  expect(find.text('GAME CONFIG'), findsOneWidget);
  // Return-from-future is set when the user taps APPLY; the caller drives that.
  return returned;
}

void main() {
  group('Around the Clock variant selector (#257)', () {
    testWidgets('renders STANDARD / REVERSE / DOUBLES ONLY options',
        (tester) async {
      await _openPanel(tester, initial: const GameConfig.aroundTheClock());

      expect(find.text('VARIANT'), findsOneWidget);
      expect(find.text('STANDARD'), findsOneWidget);
      expect(find.text('REVERSE'), findsOneWidget);
      expect(find.text('DOUBLES ONLY'), findsOneWidget);
    });

    testWidgets('selecting REVERSE flips config.variant and enables APPLY',
        (tester) async {
      GameConfig? applied;
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  applied = await showModalBottomSheet<GameConfig>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const GameConfigPanel(
                      initialConfig: GameConfig.aroundTheClock(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REVERSE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLY'));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      applied!.maybeMap(
        aroundTheClock: (c) => expect(c.variant, 'reverse'),
        orElse: () => fail('Returned config was not ATC'),
      );
    });

    testWidgets('Shanghai rounds dropdown includes 7 (the default)',
        (tester) async {
      // Regression for #259: the chip says "7 Rounds" because that's
      // the `ShanghaiGameConfig.totalRounds` default, but the dropdown
      // only listed [10, 15, 20, 25, 50] — leaving the user unable to
      // re-select 7 after editing.
      await _openPanel(tester, initial: const GameConfig.shanghai());

      expect(find.text('ROUNDS'), findsOneWidget);
      // Open the dropdown. `_RoundsDropdown` wraps `DropdownButton<int?>`.
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();

      // 7 must appear in the menu (regression: it was missing from the
      // hardcoded items list before #259).
      expect(find.text('7'), findsWidgets);
      expect(find.text('10'), findsWidgets);
      expect(find.text('15'), findsWidgets);
    });

    testWidgets('DOUBLES ONLY selection persists', (tester) async {
      GameConfig? applied;
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  applied = await showModalBottomSheet<GameConfig>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const GameConfigPanel(
                      initialConfig: GameConfig.aroundTheClock(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DOUBLES ONLY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLY'));
      await tester.pumpAndSettle();

      applied!.maybeMap(
        aroundTheClock: (c) => expect(c.variant, 'doublesOnly'),
        orElse: () => fail('Returned config was not ATC'),
      );
    });
  });

  group('LEGS TO WIN stepper accessible names (#666)', () {
    testWidgets('X01 +/- buttons expose increment/decrement semantic labels',
        (tester) async {
      await _openPanel(
        tester,
        initial: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
      );

      expect(find.text('LEGS TO WIN'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase legs to win'), findsOneWidget);
      expect(find.bySemanticsLabel('Decrease legs to win'), findsOneWidget);
    });

    testWidgets('Cricket +/- buttons expose increment/decrement semantic labels',
        (tester) async {
      await _openPanel(tester, initial: const GameConfig.cricket());

      expect(find.text('LEGS TO WIN'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase legs to win'), findsOneWidget);
      expect(find.bySemanticsLabel('Decrease legs to win'), findsOneWidget);
    });
  });

  // ── Large text (DESIGN_SYSTEM §13) ────────────────────────────────────────

  group('Sheet title at large text', () {
    const titles = {
      'fr': 'CONFIGURATION',
      'de': 'KONFIGURATION',
      'it': 'CONFIGURAZIONE',
    };
    for (final entry in titles.entries) {
      testWidgets('${entry.key} title "${entry.value}" stays on one line at '
          '2.0x', (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(entry.key),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: kSupportedLocales,
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<GameConfig>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const GameConfigPanel(
                        initialConfig: GameConfig.x01(
                          startingScore: 501,
                          inStrategy: 'straight',
                          outStrategy: 'double',
                          legsToWin: 1,
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final title = tester.renderObject<RenderParagraph>(
          find.text(entry.value),
        );
        expect(
          _lineCount(title),
          1,
          reason: 'the title must not break mid-word',
        );
        final rect = _globalRect(title);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(412));
      });
    }
  });
}

/// The number of laid-out lines of [p]: its height over one line's height.
int _lineCount(RenderParagraph p) {
  final oneLine = TextPainter(
    text: p.text,
    textScaler: p.textScaler,
    textDirection: p.textDirection,
    maxLines: 1,
  )..layout();
  final lines = (p.size.height / oneLine.height).round();
  oneLine.dispose();
  return lines;
}

/// [box]'s painted rect in global coordinates (including FittedBox scaling).
Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
