// Widget tests for GameConfigPanel — focused on per-game-type fields.
// Around the Clock variant selector (#257) is the headline coverage here:
// the panel rendered an empty body for ATC before this PR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    testWidgets('DOUBLES ONLY selection persists', (tester) async {
      GameConfig? applied;
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
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
}
