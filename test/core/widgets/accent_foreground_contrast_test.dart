// The post-game and stats surfaces drew their accent TEXT (the hero's
// emphasised stat, the breakdown winner column, the selected stats tab label
// and the impact-heatmap title) in the fixed brand neon `primaryFixed`
// (#00FFAB) in both themes. On the light greys that is 1.16–1.29:1, below
// WCAG 1.4.3 (4.5:1 text). They now resolve through
// `AppTheme.accentForeground`: the adaptive `primary` on light, the neon
// (unchanged) on dark. The stats table's BEST column used `secondary`
// (#1FC46A, 2.2:1 on light) and now uses `onSurfaceVariant` on light.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/post_game_hero_card_widget.dart';
import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/core/widgets/stats_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/player_stats_page.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/dart_heatmap_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart'
    show
        filteredPlayerStatsProvider,
        playerLegHistoryProvider,
        playerX01StartingScoresProvider;
import 'package:dart_lodge/features/statistics/presentation/widgets/stats_heatmap_section_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child, {required bool dark}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// WCAG 2.x contrast ratio of [fg] composited over the opaque [bg].
double _contrast(Color fg, Color bg) {
  final over = Color.alphaBlend(fg, bg);
  final a = over.computeLuminance();
  final b = bg.computeLuminance();
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

// The light surfaces these foregrounds sit on.
const _lightSurfaces = [
  AppColors.surface,
  AppColors.surfaceContainerLow,
  AppColors.surfaceContainer,
  AppColors.surfaceContainerHighest,
];

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void _expectReadable(Color? fg) {
  expect(fg, isNotNull);
  for (final bg in _lightSurfaces) {
    expect(
      _contrast(fg!, bg),
      greaterThanOrEqualTo(4.5),
      reason: 'contrast of $fg on $bg',
    );
  }
}

const _hero = PostGameHeroCard(
  headline: 'Alexandra',
  badge: 'WINNER',
  badgeIcon: Icons.emoji_events,
  sideStats: [
    PostGameHeroStat(label: 'AVG PPR', value: '150.5', emphasize: true),
    PostGameHeroStat(label: 'DARTS', value: '6'),
  ],
);

const _breakdown = PostGameStatsBreakdown(
  columns: [
    PostGameBreakdownColumn(
      name: 'Alexandra',
      subtitle: 'WINNER',
      emphasize: true,
    ),
    PostGameBreakdownColumn(name: 'Bob', subtitle: '#2'),
  ],
  rows: [
    PostGameBreakdownRow(
      category: 'AVG PPR',
      values: ['150.5', '40.0'],
      highlights: [true, false],
    ),
  ],
);

final _table = StatsTableWidget(
  rows: [
    StatsTableHeader('AVERAGE', col2: 'BEST'),
    StatsTableDataRow('PPR', '53.9', '75.2'),
  ],
);

void main() {
  group('AppTheme.accentForeground', () {
    testWidgets('light → primary; dark → primaryFixed (dimmed on request)', (
      tester,
    ) async {
      late Color light;
      late Color dark;
      late Color darkDim;
      late Color board;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              light = AppTheme.accentForeground(context);
              board = AppTheme.boardAccent(context);
              return const SizedBox();
            },
          ),
          dark: false,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              dark = AppTheme.accentForeground(context);
              darkDim = AppTheme.accentForeground(context, darkAlpha: 0.7);
              return const SizedBox();
            },
          ),
          dark: true,
        ),
      );
      // Let the light → dark theme animation finish.
      await tester.pumpAndSettle();

      expect(light, AppColors.primary);
      expect(board, light);
      expect(dark, AppColorsDark.primaryFixed);
      expect(darkDim, AppColorsDark.primaryFixed.withValues(alpha: 0.7));
    });
  });

  group('post-game hero card', () {
    testWidgets('light: emphasised stat and badge icon are readable; '
        'the pill and accent bar keep the neon fill', (tester) async {
      await tester.pumpWidget(_wrap(_hero, dark: false));

      expect(_textColor(tester, '150.5'), AppColors.primary);
      _expectReadable(_textColor(tester, '150.5'));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.emoji_events)).color,
        AppColors.primary,
      );
      final pill = tester.widget<Container>(
        find
            .ancestor(of: find.text('WINNER'), matching: find.byType(Container))
            .first,
      );
      expect((pill.decoration! as BoxDecoration).color, AppColors.primaryFixed);
    });

    testWidgets('dark: emphasised stat stays neon', (tester) async {
      await tester.pumpWidget(_wrap(_hero, dark: true));
      expect(_textColor(tester, '150.5'), AppColorsDark.primaryFixed);
    });
  });

  group('post-game stats breakdown', () {
    testWidgets('light: winner name, subtitle and highlight are primary', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_breakdown, dark: false));

      expect(_textColor(tester, 'Alexandra'), AppColors.primary);
      _expectReadable(_textColor(tester, 'Alexandra'));
      expect(_textColor(tester, '150.5'), AppColors.primary);
      expect(
        _textColor(tester, 'WINNER'),
        AppColors.primary.withValues(alpha: 0.7),
      );
      expect(_textColor(tester, 'Bob'), isNot(AppColors.primary));
    });

    testWidgets('dark: winner column stays neon', (tester) async {
      await tester.pumpWidget(_wrap(_breakdown, dark: true));
      expect(_textColor(tester, 'Alexandra'), AppColorsDark.primaryFixed);
      expect(_textColor(tester, '150.5'), AppColorsDark.primaryFixed);
    });
  });

  group('stats table BEST column', () {
    testWidgets('light: onSurfaceVariant, readable on the page surface', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_table, dark: false));
      final fg = _textColor(tester, '75.2');
      expect(fg, AppColors.onSurfaceVariant);
      // The stats tables sit directly on the page `surface`.
      expect(_contrast(fg!, AppColors.surface), greaterThanOrEqualTo(4.5));
    });

    testWidgets('dark: secondary, unchanged', (tester) async {
      await tester.pumpWidget(_wrap(_table, dark: true));
      expect(_textColor(tester, '75.2'), AppColorsDark.secondary);
    });
  });

  group('stats heatmap title', () {
    Widget host({required bool dark}) => ProviderScope(
      overrides: [
        dartHeatmapProvider.overrideWith(
          (ref, filter) => const [
            DartPosition(x: 0.1, y: -0.2, segment: 'T20'),
          ],
        ),
      ],
      child: _wrap(
        const StatsHeatmapSectionWidget(playerId: 'p1', gameType: GameType.x01),
        dark: dark,
      ),
    );

    testWidgets('light → primary; dark → neon', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final title = l10n.statsHeatmapTitle.toUpperCase();

      await tester.pumpWidget(host(dark: false));
      await tester.pumpAndSettle();
      expect(_textColor(tester, title), AppColors.primary);

      await tester.pumpWidget(host(dark: true));
      await tester.pumpAndSettle();
      expect(_textColor(tester, title), AppColorsDark.primaryFixed);
    });
  });

  group('player stats tab bar', () {
    Widget host({required bool dark}) => ProviderScope(
      overrides: [
        playerProvider('p1').overrideWith((ref) async => null),
        // Keep the X01 tab body loading or empty: only the TabBar is
        // under test.
        filteredPlayerStatsProvider(
          'p1',
        ).overrideWith((ref) => Completer<PlayerStats>().future),
        playerX01StartingScoresProvider(
          'p1',
        ).overrideWith((ref) async => const <int>[]),
        playerLegHistoryProvider(
          'p1',
        ).overrideWith((ref) async => const <PlayerLegSnapshot>[]),
        dartHeatmapProvider.overrideWith(
          (ref, filter) => const <DartPosition>[],
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PlayerStatsPage(playerId: 'p1'),
      ),
    );

    testWidgets('light: selected label is primary; the indicator keeps '
        'the neon', (tester) async {
      await tester.pumpWidget(host(dark: false));
      await tester.pump();
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.labelColor, AppColors.primary);
      // The tab bar sits on the page `surface`.
      expect(
        _contrast(bar.labelColor!, AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(bar.indicatorColor, AppColors.primaryFixed);
    });

    testWidgets('dark: selected label stays neon', (tester) async {
      await tester.pumpWidget(host(dark: true));
      await tester.pump();
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.labelColor, AppColorsDark.primaryFixed);
    });
  });
}
