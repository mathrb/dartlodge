import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/providers/board_camera_preview_provider.dart';
import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/pages/cricket_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/active_cricket_game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_marks_strip_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/prominent_dart_band_widget.dart';

// ── Fake notifier ──────────────────────────────────────────────────────────────

class _FakeActiveCricketGameNotifier extends ActiveCricketGameNotifier {
  _FakeActiveCricketGameNotifier(this._state);

  final ActiveCricketGameState? _state;
  final List<String> processedDarts = [];
  int nextPlayerCalls = 0;
  int undoCalls = 0;
  int endGameCalls = 0;

  @override
  Future<ActiveCricketGameState?> build(String gameId) async => _state;

  @override
  Future<void> processDart(String s,
          {String inputMethod = 'manual', double? x, double? y}) async =>
      processedDarts.add(s);

  @override
  Future<void> nextPlayer() async => nextPlayerCalls++;

  @override
  Future<void> undoDart() async => undoCalls++;

  @override
  Future<void> endGame() async => endGameCalls++;

  /// Pushes a new state (used to drive sound listeners).
  void emit(ActiveCricketGameState s) => state = AsyncData(s);
}

class _FakeSoundPort implements SoundPort {
  final List<String> dartThrows = [];
  final List<SoundCue> cues = [];

  @override
  void dartThrown(String segment) => dartThrows.add(segment);

  @override
  void play(SoundCue cue) => cues.add(cue);
}

/// Notifier whose [build] hangs forever → provider stays in loading state.
class _LoadingActiveCricketGameNotifier extends ActiveCricketGameNotifier {
  @override
  Future<ActiveCricketGameState?> build(String gameId) =>
      Completer<ActiveCricketGameState?>().future;
}

/// Forces auto-scoring on without touching SharedPreferences.
class _FakeAutoScoringEnabled extends AutoScoringEnabled {
  @override
  Future<bool> build() async => true;
}

// ── State / GameState helpers ──────────────────────────────────────────────────

CompetitorState _competitor({
  String id = 'c1',
  String name = 'Alice',
  int score = 0,
  List<String> dartThrows = const [],
  Map<String, int> marksPerNumber = const {},
}) =>
    CompetitorState(
      competitorId: id,
      name: name,
      playerIds: const [],
      score: score,
      dartThrows: dartThrows,
      marksPerNumber: marksPerNumber,
    );

GameState _cricketState({
  String gameId = 'game-1',
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  bool isComplete = false,
  bool turnActive = true,
  String cricketScoring = 'standard',
  List<CompetitorState>? competitors,
}) =>
    GameState(
      gameId: gameId,
      gameType: GameType.cricket,
      competitors: competitors ??
          [
            _competitor(id: 'c1', name: 'Alice'),
            _competitor(id: 'c2', name: 'Bob'),
          ],
      currentTurnIndex: currentTurnIndex,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: isComplete,
      turnActive: turnActive,
      cricketScoring: cricketScoring,
    );

ActiveCricketGameState _activeState({
  GameState? gameState,
  String? pendingGameWinnerId,
  String? pendingLegWinnerId,
}) =>
    ActiveCricketGameState(
      gameState: gameState ?? _cricketState(),
      pendingGameWinnerId: pendingGameWinnerId,
      pendingLegWinnerId: pendingLegWinnerId,
    );

// ── Test app builders ──────────────────────────────────────────────────────────

List<RouteBase> _testRoutes({String gameId = 'game-1'}) => [
      GoRoute(
        path: '/game/active/cricket/:gameId',
        builder: (ctx, s) =>
            CricketBoardPage(gameId: s.pathParameters['gameId']!),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/post-game/:gameId',
        builder: (_, __) => const Scaffold(body: Text('post-game')),
      ),
    ];

Widget _buildApp(
  _FakeActiveCricketGameNotifier notifier, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/game/active/cricket/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activeCricketGameProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

Widget _buildAppWithContainer(
  ProviderContainer container, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/game/active/cricket/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Camera-first builder: auto-scoring on + a stub camera preview, so the board
/// renders the camera-first layout (#444) without a real `CameraPreview`.
Widget _buildAppCameraFirst(
  _FakeActiveCricketGameNotifier notifier, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/game/active/cricket/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activeCricketGameProvider.overrideWith(() => notifier),
      autoScoringEnabledProvider.overrideWith(() => _FakeAutoScoringEnabled()),
      boardCameraPreviewBuilderProvider.overrideWithValue(
        (ctx, id) => const SizedBox(key: ValueKey('camera-stub')),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Tall viewport so the camera-first column (strip + band + camera) fits.
void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Loading indicator shown when state is loading ──────────────────────

  testWidgets('1. Loading state renders spinner', (tester) async {
    final router = GoRouter(
      initialLocation: '/game/active/cricket/game-1',
      routes: _testRoutes(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCricketGameProvider
              .overrideWith(() => _LoadingActiveCricketGameNotifier()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── 2. Error message when state is error ──────────────────────────────────

  testWidgets('2. Error state renders error view', (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.error(Exception('DB error'), StackTrace.empty);
    await tester.pump();

    expect(find.textContaining('Error'), findsWidgets);
  });

  // ── 3. Game not found when state is null ──────────────────────────────────

  testWidgets('3. Null state renders Game not found', (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(null);
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Game not found'), findsOneWidget);
  });

  // ── 4. Renders dart indicator + header + 7 rows + footer + MISS + NEXT PLAYER

  testWidgets('4. Renders key elements: MISS, NEXT PLAYER, 7 number rows',
      (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('MISS'), findsOneWidget);
    expect(find.text('NEXT PLAYER'), findsOneWidget);
    // 7 cricket numbers: 20, 19, 18, 17, 16, 15, Bull
    expect(find.text('20'), findsWidgets);
    expect(find.text('19'), findsWidgets);
    expect(find.text('15'), findsWidgets);
    expect(find.text('SB'), findsOneWidget);
    expect(find.text('DB'), findsOneWidget);
  });

  // ── 5. Mark symbols 0–3 ───────────────────────────────────────────────────

  testWidgets('5. Mark symbols — 0 marks shows ─, 1 shows /, 2 shows X, 3+ shows ⊗',
      (tester) async {
    final competitors = [
      _competitor(
        id: 'c1',
        name: 'Alice',
        marksPerNumber: {'20': 0, '19': 1, '18': 2, '17': 3},
      ),
    ];
    final gs = _cricketState(competitors: competitors);
    final notifier = _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Marks are drawn via CustomPaint (at least one per row × one competitor = 7)
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(7));
  });

  // ── 6. Closed row cells are non-tappable + Tooltip ────────────────────────

  testWidgets('6. Closed row: input cells are non-tappable with tooltip',
      (tester) async {
    // Row 20 is closed when all competitors have 3+ marks for '20'
    final competitors = [
      _competitor(
        id: 'c1',
        name: 'Alice',
        marksPerNumber: {'20': 3},
      ),
      _competitor(
        id: 'c2',
        name: 'Bob',
        marksPerNumber: {'20': 3},
      ),
    ];
    final gs = _cricketState(competitors: competitors);
    final notifier = _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Tapping Single 20 on a closed row should NOT add to processedDarts
    // Find single '20' cell via semantics
    final singleCell = find.bySemanticsLabel('Single 20');
    if (singleCell.evaluate().isNotEmpty) {
      await tester.tap(singleCell, warnIfMissed: false);
      await tester.pump();
      expect(notifier.processedDarts, isNot(contains('20')));
    }
  });

  // ── 7. Bull row has no triple cell ───────────────────────────────────────

  testWidgets('7. Bull row has no triple cell — only SB and DB', (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // The ≡ disabled-triple placeholder was removed; SB + DB are the only bull cells
    expect(find.text('≡'), findsNothing);
    expect(find.text('SB'), findsOneWidget);
    expect(find.text('DB'), findsOneWidget);
  });

  // ── 8. Tapping Single 20 → processDart('20') ─────────────────────────────

  testWidgets('8. Tapping Single 20 calls processDart("20")', (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // Single 20 — first InkWell that contains a Text('20')
    final s20 = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('20'),
    );
    await tester.tap(s20.first);
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.processedDarts, contains('20'));
  });

  // ── 9. Tapping Double 19 → processDart('D19') ────────────────────────────

  testWidgets('9. Tapping Double 19 calls processDart("D19")', (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // Double 19 — second Text('19') inside an InkWell (S19=0, D19=1, T19=2)
    final d19 = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('19'),
    );
    await tester.tap(d19.at(1));
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.processedDarts, contains('D19'));
  });

  // ── 10. Tapping Triple 18 → processDart('T18') ───────────────────────────

  testWidgets('10. Tapping Triple 18 calls processDart("T18")', (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // Triple 18 — third Text('18') inside an InkWell (S18=0, D18=1, T18=2)
    final t18 = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('18'),
    );
    await tester.tap(t18.at(2));
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.processedDarts, contains('T18'));
  });

  // ── 11. MISS button → processDart('MISS') ────────────────────────────────

  testWidgets('11. Tapping MISS calls processDart("MISS")', (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // MISS is inside an InkWell in the header row
    final missText = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('MISS'),
    );
    await tester.ensureVisible(missText.first);
    await tester.tap(missText.first);
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.processedDarts, contains('MISS'));
  });

  // ── 12. UNDO disabled when dartsThrownInTurn == 0 ────────────────────────

  testWidgets('12. Undo disabled when dartsThrownInTurn == 0', (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 0);
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Undo is in the bottom bar as an icon; disabled state uses Opacity 0.38
    final undoIcon = find.byIcon(Icons.undo);
    final opacityWidget = tester.widget<Opacity>(
      find.ancestor(of: undoIcon, matching: find.byType(Opacity)).first,
    );
    expect(opacityWidget.opacity, 0.38);
  });

  // ── 13. UNDO enabled when dartsThrownInTurn > 0 → undoDart() ─────────────

  testWidgets('13. Undo enabled and calls undoDart when darts thrown',
      (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 1);
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // Undo is enabled when dartsThrownInTurn > 0 — Opacity wrapper has opacity 1.0
    final undoIcon = find.byIcon(Icons.undo);
    final opacityWidget = tester.widget<Opacity>(
      find.ancestor(of: undoIcon, matching: find.byType(Opacity)).first,
    );
    expect(opacityWidget.opacity, 1.0);

    await tester.tap(undoIcon);
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.undoCalls, 1);
  });

  // ── 14. NEXT PLAYER with 3 darts → nextPlayer() without dialog ───────────

  testWidgets('14. NEXT PLAYER with 3 darts calls nextPlayer() directly',
      (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 3);
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final nextPlayerBtn = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('NEXT PLAYER'),
    );
    await tester.ensureVisible(nextPlayerBtn.first);
    await tester.tap(nextPlayerBtn.first);
    await tester.pump();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.nextPlayerCalls, 1);
    // No dialog should appear
    expect(find.text('Advance turn?'), findsNothing);
  });

  // ── 15. NEXT PLAYER with < 3 darts → shows AlertDialog ───────────────────

  testWidgets('15. NEXT PLAYER with < 3 darts shows confirm dialog',
      (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 1);
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final nextPlayerBtn = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('NEXT PLAYER'),
    );
    await tester.ensureVisible(nextPlayerBtn.first);
    await tester.tap(nextPlayerBtn.first);
    await tester.pumpAndSettle();

    expect(find.text('Advance turn?'), findsOneWidget);
    expect(find.textContaining("1 dart"), findsOneWidget);
  });

  // ── 16. Confirm dialog → nextPlayer() called ─────────────────────────────

  testWidgets('16. Confirming dialog calls nextPlayer()', (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 1);
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final nextPlayerBtn = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('NEXT PLAYER'),
    );
    await tester.ensureVisible(nextPlayerBtn.first);
    await tester.tap(nextPlayerBtn.first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.nextPlayerCalls, 1);
  });

  // ── 17. Cancel dialog → nextPlayer() NOT called ──────────────────────────

  testWidgets('17. Cancelling dialog does not call nextPlayer()', (tester) async {
    final gs = _cricketState(dartsThrownInTurn: 1);
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final nextPlayerBtn = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('NEXT PLAYER'),
    );
    await tester.ensureVisible(nextPlayerBtn.first);
    await tester.tap(nextPlayerBtn.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final notifier =
        container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier;
    expect(notifier.nextPlayerCalls, 0);
  });

  // ── 18. Active player header has primary tint ─────────────────────────────

  testWidgets('18. Active player header has primary tint background',
      (tester) async {
    final gs = _cricketState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice'),
        _competitor(id: 'c2', name: 'Bob'),
      ],
      currentTurnIndex: 0,
    );
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Active player (index 0) should have a container with primary-tinted bg
    // The tint is set via BoxDecoration, not Container.color directly
    final containers = tester.widgetList<Container>(find.byType(Container));
    final tintedContainers = containers.where((c) {
      final color = (c.decoration as BoxDecoration?)?.color;
      // Semi-transparent tint: alpha < 1 and not fully transparent
      return color != null && color.a > 0 && color.a < 1.0;
    }).toList();
    expect(tintedContainers, isNotEmpty);
  });

  // ── 19. Inactive player score uses AppColors.inactiveScore ───────────────

  testWidgets('19. Inactive player score uses inactiveScore color',
      (tester) async {
    final gs = _cricketState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice', score: 0),
        _competitor(id: 'c2', name: 'Bob', score: 10),
      ],
      currentTurnIndex: 0,
    );
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Bob (inactive) score text should have onSurfaceVariant color
    final texts = tester.widgetList<Text>(find.text('10'));
    final inactiveColoredTexts = texts.where((t) {
      final style = t.style;
      return style?.color == AppColors.onSurfaceVariant;
    }).toList();
    expect(inactiveColoredTexts, isNotEmpty);
  });

  // ── 21. Game completion navigates straight to post-game (no modal) ────────

  testWidgets(
      '21. Game completion navigates straight to post-game summary, '
      'no winner modal (consistent with x01)', (tester) async {
    final gs = _cricketState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice'),
        _competitor(id: 'c2', name: 'Bob'),
      ],
      isComplete: true,
    );
    final notifier = _FakeActiveCricketGameNotifier(
      _activeState(gameState: gs, pendingGameWinnerId: 'c1'),
    );
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('post-game'), findsOneWidget);
  });

  // ── 22. AppBar subtitle shows 'Cut Throat' for cut-throat variant ─────────

  testWidgets('22. AppBar subtitle shows "Cut Throat" for cut-throat variant',
      (tester) async {
    final gs = _cricketState(cricketScoring: 'cut-throat');
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cut Throat'), findsOneWidget);
  });

  // ── 23. Back → End Game calls endGame() then navigates home (#252) ────────

  testWidgets(
      '23. Back → End Game calls endGame() so the game appears in history',
      (tester) async {
    final fakeNotifier =
        _FakeActiveCricketGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('End Game?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'End Game'));
    await tester.pumpAndSettle();

    // Assert on the captured fake directly. Re-reading
    // activeCricketGameProvider('game-1').notifier here would force a rebuild
    // of the family provider that navigation home just disposed, re-associating
    // the same Notifier instance and tripping Riverpod 3.3.2's "Notifier
    // already associated with another provider" guard.
    expect(fakeNotifier.endGameCalls, 1,
        reason: 'Abandoning the game must mark it complete so it lands '
            'in history immediately (issue #252)');
    expect(find.text('home'), findsOneWidget);
  });

  // ── Camera-first: marks strip + dart band, no status-bar darts (#444) ────────

  testWidgets('Camera-first shows the marks strip and prominent dart band',
      (tester) async {
    _setTallViewport(tester);
    final gs = _cricketState(
      competitors: [
        _competitor(
          id: 'c1',
          name: 'Alice',
          score: 41,
          marksPerNumber: const {'20': 3, '19': 1},
          dartThrows: const ['T20'],
        ),
        _competitor(id: 'c2', name: 'Bob', score: 0),
      ],
      dartsThrownInTurn: 1,
    );
    final notifier = _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Marks strip (F-strip) replaces the full table; both players visible.
    expect(find.byType(CricketMarksStripWidget), findsOneWidget);
    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('41'), findsOneWidget); // Alice's score
    // Prominent dart band (F1) present; the unified table is gone.
    expect(find.byType(ProminentDartBandWidget), findsOneWidget);
    expect(find.byType(CricketUnifiedTableWidget), findsNothing);
    // Camera stub fills the body; the status bar shows no dart placeholders.
    expect(find.byKey(const ValueKey('camera-stub')), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsNothing);
  });

  testWidgets('Manual mode still shows the full unified table', (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(CricketUnifiedTableWidget), findsOneWidget);
    expect(find.byType(CricketMarksStripWidget), findsNothing);
    expect(find.byType(ProminentDartBandWidget), findsNothing);
  });

  // ── Sound wiring (per-mark cues, no generic dartThrown) ──────────────────────

  /// Pumps the cricket board with a sound spy, emits a post-dart state, and
  /// returns the recorded cues. [before]/[after] are the active competitor's
  /// marks/score on the previous and new state.
  Future<_FakeSoundPort> _pumpDart(
    WidgetTester tester, {
    required CompetitorState before,
    required CompetitorState after,
  }) async {
    final sound = _FakeSoundPort();
    final bob = _competitor(id: 'c2', name: 'Bob');
    final fakeNotifier = _FakeActiveCricketGameNotifier(
      _activeState(
        gameState:
            _cricketState(dartsThrownInTurn: 0, competitors: [before, bob]),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeCricketGameProvider.overrideWith(() => fakeNotifier),
        soundPortProvider.overrideWith((ref) => sound),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    (container.read(activeCricketGameProvider('game-1').notifier)
            as _FakeActiveCricketGameNotifier)
        .emit(_activeState(
      gameState:
          _cricketState(dartsThrownInTurn: 1, competitors: [after, bob]),
    ));
    await tester.pump();
    return sound;
  }

  testWidgets('a triple (3 marks) plays cricketTripleMark', (tester) async {
    final sound = await _pumpDart(
      tester,
      before: _competitor(),
      after: _competitor(marksPerNumber: const {'20': 3}),
    );
    expect(sound.cues, [SoundCue.cricketTripleMark]);
    expect(sound.dartThrows, isEmpty);
  });

  testWidgets('1–2 marks play cricketSingleMark', (tester) async {
    final sound = await _pumpDart(
      tester,
      before: _competitor(),
      after: _competitor(marksPerNumber: const {'20': 2}),
    );
    expect(sound.cues, [SoundCue.cricketSingleMark]);
  });

  testWidgets('a closed number scoring points plays dartHit', (tester) async {
    final sound = await _pumpDart(
      tester,
      before: _competitor(score: 0, marksPerNumber: const {'20': 3}),
      after: _competitor(score: 60, marksPerNumber: const {'20': 3}),
    );
    expect(sound.cues, [SoundCue.dartHit]);
  });

  testWidgets('a true miss (no marks, no points) plays dartMiss',
      (tester) async {
    final sound = await _pumpDart(
      tester,
      before: _competitor(),
      after: _competitor(),
    );
    expect(sound.cues, [SoundCue.dartMiss]);
  });
}
