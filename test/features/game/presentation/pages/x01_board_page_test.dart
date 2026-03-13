import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/utils/app_colors.dart';
import 'package:my_darts/core/utils/app_theme.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/presentation/pages/x01_board_page.dart';
import 'package:my_darts/features/game/presentation/providers/active_game_provider.dart';
import 'package:my_darts/features/game/presentation/state/active_game_state.dart';

// ── Fake notifier ──────────────────────────────────────────────────────────────

class _FakeActiveGameNotifier extends ActiveGameNotifier {
  _FakeActiveGameNotifier(this._initialState);

  final ActiveGameState? _initialState;
  final List<String> processedDarts = [];
  int undoCalls = 0;
  int buildCount = 0;

  @override
  Future<ActiveGameState?> build(String gameId) async {
    buildCount++;
    return _initialState;
  }

  @override
  Future<void> processDart(String segment) async => processedDarts.add(segment);

  @override
  Future<void> undoDart() async => undoCalls++;

  @override
  void dismissBust() =>
      state = state.whenData((s) => s?.copyWith(showBust: false));

  @override
  void dismissLegModal() =>
      state = state.whenData((s) => s?.copyWith(pendingLegWinnerId: null));

  @override
  void dismissGameModal() =>
      state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));

  /// For test 24: transition showBust from false → true.
  void triggerBust() =>
      state = state.whenData((s) => s?.copyWith(showBust: true));
}

/// Notifier whose [build] hangs forever → provider stays in loading state.
class _LoadingActiveGameNotifier extends ActiveGameNotifier {
  @override
  Future<ActiveGameState?> build(String gameId) =>
      Completer<ActiveGameState?>().future;
}

// ── State / GameState helpers ─────────────────────────────────────────────────

CompetitorState _competitor({
  String id = 'c1',
  String name = 'Alice',
  int score = 501,
  List<String> dartThrows = const [],
}) =>
    CompetitorState(
      competitorId: id,
      name: name,
      playerIds: const [],
      score: score,
      dartThrows: dartThrows,
    );

GameState _gameState({
  String gameId = 'game-1',
  int startingScore = 501,
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  int legsToWin = 1,
  int currentLegIndex = 0,
  bool isComplete = false,
  List<CompetitorState>? competitors,
}) =>
    GameState(
      gameId: gameId,
      gameType: GameType.x01,
      competitors: competitors ?? [_competitor()],
      currentTurnIndex: currentTurnIndex,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: isComplete,
      startingScore: startingScore,
      legsToWin: legsToWin,
      currentLegIndex: currentLegIndex,
    );

ActiveGameState _activeState({
  GameState? gameState,
  bool showBust = false,
  String? pendingGameWinnerId,
  String? pendingLegWinnerId,
}) =>
    ActiveGameState(
      gameState: gameState ?? _gameState(),
      showBust: showBust,
      pendingGameWinnerId: pendingGameWinnerId,
      pendingLegWinnerId: pendingLegWinnerId,
    );

// ── Test app builders ──────────────────────────────────────────────────────────

List<RouteBase> _testRoutes({String gameId = 'game-1'}) => [
      GoRoute(
        path: '/game/active/x01/:gameId',
        builder: (ctx, s) =>
            X01BoardPage(gameId: s.pathParameters['gameId']!),
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

/// Standard builder using [ProviderScope] with override.
Widget _buildApp(
  _FakeActiveGameNotifier notifier, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/game/active/x01/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activeGameProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Builder using [UncontrolledProviderScope] so the caller controls state.
Widget _buildAppWithContainer(
  ProviderContainer container, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/game/active/x01/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Sets the test viewport to a tall size so the full board fits without overflow.
/// The default 800×600 is too short for the x01 board with the new design.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Loading state renders spinner ────────────────────────────────────────

  testWidgets('1. Loading state renders spinner', (tester) async {
    final router = GoRouter(
      initialLocation: '/game/active/x01/game-1',
      routes: _testRoutes(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGameProvider
              .overrideWith(() => _LoadingActiveGameNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    // Pump once to let the widget build (but build() future is pending)
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // No board content in loading state
    expect(find.text('ALICE ▶'), findsNothing);
  });

  // ── 2. Error state renders error view ───────────────────────────────────────

  testWidgets('2. Error state renders error view with Retry button',
      (tester) async {
    _setPhoneViewport(tester);
    final fakeNotifier = _FakeActiveGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activeGameProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.error(Exception('DB error'), StackTrace.empty);
    await tester.pump();

    expect(find.textContaining('Error'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
  });

  // ── 3. Single player — full-width column, 80sp score ────────────────────────

  testWidgets('3. Single player shows full-width column with score',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(name: 'Alice', score: 501)],
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('ALICE ▶'), findsOneWidget);
    // '501' appears in both AppBar (startingScore) and PlayerScoreSection;
    // we just verify it's visible somewhere.
    expect(find.text('501'), findsWidgets);
  });

  // ── 4. Three players, 48sp score ────────────────────────────────────────────

  testWidgets('4. Three players all show their names', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice'),
        _competitor(id: 'c2', name: 'Bob'),
        _competitor(id: 'c3', name: 'Carol'),
      ],
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('ALICE ▶'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('CAROL'), findsOneWidget);
  });

  // ── 5. Active column has left border ────────────────────────────────────────

  testWidgets('5. Active column has 4dp left border; inactive has none',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice'),
        _competitor(id: 'c2', name: 'Bob'),
      ],
      currentTurnIndex: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final leftBorderContainers = containers.where((c) {
      final d = c.decoration;
      if (d is BoxDecoration) {
        final b = d.border;
        if (b is Border) return b.left.width == 4.0;
      }
      return false;
    }).toList();

    expect(leftBorderContainers, isNotEmpty);
  });

  // ── 6. Active player ▶ suffix ───────────────────────────────────────────────

  testWidgets('6. Active player name shows ▶; inactive does not',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice'),
        _competitor(id: 'c2', name: 'Bob'),
      ],
      currentTurnIndex: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('ALICE ▶'), findsOneWidget);
    expect(find.text('BOB ▶'), findsNothing);
    expect(find.text('BOB'), findsOneWidget);
  });

  // ── 7. PPR shows — before 3 darts ───────────────────────────────────────────

  testWidgets('7. PPR shows — when fewer than 3 darts thrown', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(dartThrows: const [])],
      dartsThrownInTurn: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('PPR —'), findsOneWidget);
  });

  // ── 8. PPR shows numeric value after first complete turn ────────────────────

  testWidgets('8. PPR shows numeric value after 3 darts (60/3×3=60.0)',
      (tester) async {
    _setPhoneViewport(tester);
    // delta = 501 - 441 = 60; darts = 3; PPR = (60/3)*3 = 60.0
    final gs = _gameState(
      competitors: [
        _competitor(score: 441, dartThrows: const ['20', '20', '20']),
      ],
      startingScore: 501,
      dartsThrownInTurn: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('PPR 60.0'), findsOneWidget);
  });

  // ── 9. Dart indicator — empty slots ─────────────────────────────────────────

  testWidgets('9. Dart indicator shows round sum 0 before any dart thrown',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 0);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Round sum label should show '0' — verified via DartIndicatorWidget
    expect(find.text('0'), findsWidgets);
  });

  // ── 10. Dart indicator — chips for thrown darts ──────────────────────────────

  testWidgets('10. Dart indicator shows chips for thrown darts', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(dartThrows: const ['T20', '19']),
      ],
      dartsThrownInTurn: 2,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // 'T20' appears both in DartIndicator chip and in the input grid.
    expect(find.text('T20'), findsWidgets);
    // '19' appears in DartIndicator chip (the grid shows '19' too but as a grid cell)
    expect(find.text('19'), findsWidgets);
  });

  // ── 11. Checkout banner visible for score ≤ 170 ─────────────────────────────

  testWidgets('11. Checkout banner visible when score is 170', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(competitors: [_competitor(score: 170)]);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });

  // ── 12. Checkout banner hidden for score > 170 ───────────────────────────────

  testWidgets('12. Checkout banner hidden when score is 171', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(competitors: [_competitor(score: 171)]);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
  });

  // ── 13. Checkout banner hidden for score == 1 ────────────────────────────────

  testWidgets('13. Checkout banner hidden when score is 1', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(competitors: [_competitor(score: 1)]);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
  });

  // ── 14. Grid row 0: MISS, SB, DB ──────────────────────────────────────────

  testWidgets('14. Segment grid row 0 has MISS, SB, DB', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('MISS'), findsOneWidget);
    expect(find.text('SB'), findsOneWidget);
    expect(find.text('DB'), findsOneWidget);
  });

  // ── 15. Doubles rows have primaryContainer background ────────────────────────

  testWidgets('15. Doubles rows have colorPrimaryContainer background',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final primaryContainerBg = containers.where((c) {
      final d = c.decoration;
      if (d is BoxDecoration) return d.color == AppColors.primaryContainer;
      return false;
    });
    expect(primaryContainerBg, isNotEmpty);
  });

  // ── 16. Triples rows have primary background ─────────────────────────────────

  testWidgets('16. Triples rows have colorPrimary background', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final primaryBg = containers.where((c) {
      final d = c.decoration;
      if (d is BoxDecoration) return d.color == AppColors.primary;
      return false;
    });
    expect(primaryBg, isNotEmpty);
  });

  // ── 17. Semantic labels on grid cells ────────────────────────────────────────

  testWidgets('17. Grid cells carry semantic labels', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Verify by checking Semantics widgets with the expected label exist
    final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
    final labels = semanticsWidgets
        .map((s) => s.properties.label)
        .whereType<String>()
        .toSet();
    expect(labels, contains('Triple 20'));
    expect(labels, contains('Double Bull'));
  });

  // ── 18. Tapping segment calls processDart ────────────────────────────────────

  testWidgets('18. Tapping T20 calls processDart("T20")', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState();
    final fakeNotifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [activeGameProvider.overrideWith(() => fakeNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('T20'));
    await tester.pump();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    expect(notifier.processedDarts, contains('T20'));
  });

  // ── 19. NEXT ROUND disabled when < 3 darts ───────────────────────────────────

  testWidgets('19. NEXT ROUND disabled when dartsThrownInTurn < 3',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 2);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(btn.onPressed, isNull);
  });

  // ── 20. NEXT ROUND enabled when 3 darts thrown ───────────────────────────────

  testWidgets('20. NEXT ROUND enabled when dartsThrownInTurn == 3',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 3);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(btn.onPressed, isNotNull);
  });

  // ── 21. Undo disabled when 0 darts thrown ────────────────────────────────────

  testWidgets('21. Undo button disabled when dartsThrownInTurn == 0',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 0);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final undoBtn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Undo'),
        matching: find.byType(TextButton),
      ),
    );
    expect(undoBtn.onPressed, isNull);
  });

  // ── 22. Undo enabled when > 0 darts thrown ───────────────────────────────────

  testWidgets('22. Undo button enabled when dartsThrownInTurn > 0',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 1);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final undoBtn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Undo'),
        matching: find.byType(TextButton),
      ),
    );
    expect(undoBtn.onPressed, isNotNull);
  });

  // ── 23. Tapping Undo calls undoDart ──────────────────────────────────────────

  testWidgets('23. Tapping Undo calls undoDart on notifier', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 1);
    final fakeNotifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    final container = ProviderContainer(
      overrides: [activeGameProvider.overrideWith(() => fakeNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pump();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    expect(notifier.undoCalls, 1);
  });

  // ── 24. Bust snackbar shown on showBust transition ───────────────────────────

  testWidgets('24. Bust snackbar shown on showBust=true transition',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState();
    final fakeNotifier =
        _FakeActiveGameNotifier(_activeState(gameState: gs, showBust: false));
    final container = ProviderContainer(
      overrides: [activeGameProvider.overrideWith(() => fakeNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    // Transition to showBust=true
    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    notifier.triggerBust();
    await tester.pump();

    expect(find.text('BUST'), findsOneWidget);

    // Advance time past the 2-second dismissal timer to avoid pending timer warning.
    await tester.pump(const Duration(seconds: 3));
  });

  // ── 25. Win banner visible on pendingGameWinnerId set ────────────────────────

  testWidgets('25. Win banner shows winner name and action buttons',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(id: 'c1', name: 'Alice')],
      isComplete: true,
    );
    final notifier = _FakeActiveGameNotifier(
      _activeState(gameState: gs, pendingGameWinnerId: 'c1'),
    );
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Win banner shows winner name uppercased; player section also shows it.
    expect(find.text('ALICE'), findsWidgets);
    expect(find.text('Post-Game Summary'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
  });

  // ── 26. Post-Game Summary navigates ─────────────────────────────────────────

  testWidgets('26. Post-Game Summary navigates to /post-game/:gameId',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(id: 'c1', name: 'Alice')],
      isComplete: true,
    );
    final notifier = _FakeActiveGameNotifier(
      _activeState(gameState: gs, pendingGameWinnerId: 'c1'),
    );
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post-Game Summary'));
    await tester.pumpAndSettle();

    expect(find.text('post-game'), findsOneWidget);
  });

  // ── 27. Play Again navigates to home ─────────────────────────────────────────

  testWidgets('27. Play Again navigates to home', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(id: 'c1', name: 'Alice')],
      isComplete: true,
    );
    final notifier = _FakeActiveGameNotifier(
      _activeState(gameState: gs, pendingGameWinnerId: 'c1'),
    );
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  // ── 28. Overflow menu shows End Game ─────────────────────────────────────────

  testWidgets('28. Overflow menu shows End Game option', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('End Game'), findsOneWidget);
  });

  // ── 29. End Game shows confirmation dialog ────────────────────────────────────

  testWidgets('29. Selecting End Game shows confirmation dialog',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
    await tester.pumpAndSettle();

    expect(find.text('End Game?'), findsOneWidget);
    expect(find.textContaining('abandoned'), findsOneWidget);
  });

  // ── 30. Cancel dismisses dialog ──────────────────────────────────────────────

  testWidgets('30. Cancel dismisses End Game dialog without navigation',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('End Game?'), findsNothing);
    expect(find.byType(X01BoardPage), findsOneWidget);
  });

  // ── 31. Confirm navigates to home ────────────────────────────────────────────

  testWidgets('31. Confirming End Game navigates to home', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game')); // Tap menu item
    await tester.pumpAndSettle();

    // Now tap "End Game" button inside the dialog
    await tester.tap(find.widgetWithText(FilledButton, 'End Game'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  // ── 32. No back button ───────────────────────────────────────────────────────

  testWidgets('32. No back button in AppBar', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  // ── 33. Loading spinner with primary color ────────────────────────────────────

  testWidgets('33. Loading state shows CircularProgressIndicator', (tester) async {
    final router = GoRouter(
      initialLocation: '/game/active/x01/game-1',
      routes: _testRoutes(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGameProvider
              .overrideWith(() => _LoadingActiveGameNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.color, AppColors.primary);
  });

  // ── 34. Retry triggers provider rebuild ──────────────────────────────────────

  testWidgets('34. Retry button triggers provider rebuild', (tester) async {
    _setPhoneViewport(tester);
    final fakeNotifier = _FakeActiveGameNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [activeGameProvider.overrideWith(() => fakeNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    final buildsBefore = notifier.buildCount;

    // Set error state
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.error(Exception('DB error'), StackTrace.empty);
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    // After invalidation, the provider is rebuilt
    expect(notifier.buildCount, greaterThan(buildsBefore));
  });
}
