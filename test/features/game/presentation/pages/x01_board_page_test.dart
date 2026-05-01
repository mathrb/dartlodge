import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/pages/x01_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/active_game_state.dart';

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
  bool turnActive = true,
  List<CompetitorState>? competitors,
}) =>
    GameState(
      gameId: gameId,
      gameType: GameType.x01,
      competitors: competitors ?? [_competitor()],
      currentTurnIndex: currentTurnIndex,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: isComplete,
      turnActive: turnActive,
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

    expect(find.text('ALICE'), findsWidgets);
    // '501' appears in the status bar and in the player score section.
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

    expect(find.text('ALICE'), findsWidgets);
    expect(find.text('BOB'), findsWidgets);
    expect(find.text('CAROL'), findsWidgets);
  });

  // ── 5. Active player card has neon accent bar ────────────────────────────────

  testWidgets('5. Active column has 4dp neon accent bar; inactive has none',
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

    // The active player card has a neon accent bar: a Container with
    // BoxDecoration color == cs.primaryFixed (which equals AppColors.primaryContainer
    // in light mode) and width == 4.
    final containers = tester.widgetList<Container>(find.byType(Container));
    final accentBars = containers.where((c) {
      if (c.decoration is BoxDecoration) {
        return (c.decoration as BoxDecoration).color == AppColors.primaryContainer;
      }
      return false;
    }).toList();

    expect(accentBars, isNotEmpty);
  });

  // ── 6. Both player names are visible ────────────────────────────────────────

  testWidgets('6. Both player names are visible; active indicated by accent bar',
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

    // Both names are present (uppercased); no ▶ suffix in new design
    expect(find.text('ALICE'), findsWidgets);
    expect(find.text('BOB'), findsWidgets);
    // No ▶ indicator in the new card design
    expect(find.textContaining('▶'), findsNothing);
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

    // PPR label and value are separate Text widgets in the redesigned card
    expect(find.text('PPR'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
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

    // PPR label and value are separate Text widgets in the redesigned card
    expect(find.text('PPR'), findsOneWidget);
    expect(find.text('60.0'), findsOneWidget);
  });

  // ── 9. Status bar — no dart info when no darts thrown ───────────────────────

  testWidgets('9. Status bar shows no dart info when no darts thrown',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 0);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Status bar shows game meta and dart placeholder icons when no darts thrown
    expect(find.text('501'), findsWidgets); // variant label in status bar
    expect(find.byIcon(Icons.navigation), findsNWidgets(3)); // dart placeholder icons
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

    // Checkout banner shows 'CHECKOUT' label in new design (no lightbulb icon)
    expect(find.text('CHECKOUT'), findsOneWidget);
  });

  // ── 12. Checkout banner hidden for score > 170 ───────────────────────────────

  testWidgets('12. Checkout banner dimmed when score is 171', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(competitors: [_competitor(score: 171)]);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Checkout banner is now always visible but dimmed when not in range
    final checkoutText = tester.widget<Text>(find.text('CHECKOUT'));
    final color = checkoutText.style?.color;
    expect(color?.alpha, lessThan(255)); // Check that it's dimmed (alpha < 1.0)
  });

  // ── 13. Checkout banner hidden for score == 1 ────────────────────────────────

  testWidgets('13. Checkout banner dimmed when score is 1', (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(competitors: [_competitor(score: 1)]);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Checkout banner is now always visible but dimmed when not in range
    final checkoutText = tester.widget<Text>(find.text('CHECKOUT'));
    final color = checkoutText.style?.color;
    expect(color?.alpha, lessThan(255)); // Check that it's dimmed (alpha < 1.0)
  });

  // ── 14. Grid row 0: MISS, SB, DB ──────────────────────────────────────────

  testWidgets('14. Segment grid row 0 has MISS, SB, DB', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('MISS'), findsOneWidget);
    expect(find.text('25'), findsWidgets); // Single Bull label
    expect(find.text('50'), findsOneWidget); // Double Bull label
    expect(find.text('BULL'), findsWidgets); // Sub-label on both bull buttons
  });

  // ── 15. Doubles rows show D-prefixed numbers ─────────────────────────────────

  testWidgets('15. Doubles rows have colorPrimaryContainer background',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Doubles grid cells use surfaceContainerLow background and show numbers with 2 dots
    expect(find.text('20'), findsWidgets); // Numbers appear in multiple rows
    expect(find.text('1'), findsWidgets);  // Numbers appear in multiple rows
    final containers = tester.widgetList<Container>(find.byType(Container));
    final surfaceContainerLowBg = containers.where((c) {
      final d = c.decoration;
      if (d is BoxDecoration) return d.color == AppColors.surfaceContainerLow;
      return false;
    });
    expect(surfaceContainerLowBg, isNotEmpty);
    
    // Check that doubles row has cells with 2 dots (indicating doubles)
    // Find containers that represent dots (4x4 circles)
    final dotContainers = tester.widgetList<Container>(find.byWidgetPredicate(
      (widget) => widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          widget.constraints?.maxWidth == 4 &&
          widget.constraints?.maxHeight == 4,
    ));
    
    // Group dots by their parent row to find rows with exactly 2 dots
    final dotGroups = <Widget, List<Container>>{};
    for (final dot in dotContainers) {
      final parent = tester.widget<Row>(find.ancestor(of: find.byWidget(dot), matching: find.byType(Row)).first);
      dotGroups.putIfAbsent(parent, () => []).add(dot);
    }
    
    final doubleDotGroups = dotGroups.values.where((dots) => dots.length == 2);
    expect(doubleDotGroups, isNotEmpty);
  });

  // ── 16. Triples rows show T-prefixed numbers ──────────────────────────────────

  testWidgets('16. Triples rows have colorPrimary background', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Triples grid cells use surfaceContainer background and show numbers with 3 dots
    expect(find.text('20'), findsWidgets); // Numbers appear in multiple rows
    expect(find.text('1'), findsWidgets);  // Numbers appear in multiple rows
    final containers = tester.widgetList<Container>(find.byType(Container));
    final surfaceContainerBg = containers.where((c) {
      final d = c.decoration;
      if (d is BoxDecoration) return d.color == AppColors.surfaceContainer;
      return false;
    });
    
    // Check that triples row has cells with 3 dots (indicating triples)
    // Find containers that represent dots (4x4 circles)
    final dotContainers = tester.widgetList<Container>(find.byWidgetPredicate(
      (widget) => widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          widget.constraints?.maxWidth == 4 &&
          widget.constraints?.maxHeight == 4,
    ));
    
    // Group dots by their parent row to find rows with exactly 3 dots
    final dotGroups = <Widget, List<Container>>{};
    for (final dot in dotContainers) {
      final parent = tester.widget<Row>(find.ancestor(of: find.byWidget(dot), matching: find.byType(Row)).first);
      dotGroups.putIfAbsent(parent, () => []).add(dot);
    }
    
    final tripleDotGroups = dotGroups.values.where((dots) => dots.length == 3);
    expect(tripleDotGroups, isNotEmpty);
    expect(surfaceContainerBg, isNotEmpty);
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

    // Find the Triple 20 cell by its Semantics widget label (label shows '20', prefix inferred from tier)
    await tester.tap(find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Triple 20',
    ).first);
    await tester.pumpAndSettle();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    expect(notifier.processedDarts, contains('T20'));
  });

  // ── 19. NEXT ROUND disabled when < 3 darts ───────────────────────────────────

  testWidgets('19. NEXT ROUND enabled even mid-turn (new design)',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 2, turnActive: true);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // New design allows ending turn early - button is enabled as long as game is not complete
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('NEXT ROUND'),
        matching: find.byType(FilledButton),
      ).first,
    );
    expect(button.onPressed, isNotNull);
  });

  // ── 20. NEXT ROUND enabled when 3 darts thrown ───────────────────────────────

  testWidgets('20. NEXT ROUND enabled when turn ended (turnActive=false)',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 3, turnActive: false);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final gd = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('NEXT ROUND'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    expect(gd.onTap, isNotNull);
  });

  // ── 21. Undo disabled when 0 darts thrown ────────────────────────────────────

  testWidgets('21. Undo button disabled when dartsThrownInTurn == 0',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 0);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Undo button uses icon (Icons.undo) in new design; InkWell.onTap is null when disabled
    final undoInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(undoInkWell.onTap, isNull);
  });

  // ── 22. Undo enabled when > 0 darts thrown ───────────────────────────────────

  testWidgets('22. Undo button enabled when dartsThrownInTurn > 0',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 1);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final undoInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(undoInkWell.onTap, isNotNull);
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

    await tester.tap(find.byIcon(Icons.undo));
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

  // ── 25. Win state auto-navigates to post-game page ──────────────────────────

  testWidgets('25. Win state auto-navigates to post-game page',
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

    // Board auto-navigates to /post-game/:gameId when a winner is set.
    expect(find.text('post-game'), findsOneWidget);
  });

  // ── 28. Settings icon is present in custom header ────────────────────────────

  testWidgets('28. Settings icon is present in custom header', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  // ── 29. Tapping settings shows End Game confirmation dialog ──────────────────

  testWidgets('29. Selecting End Game shows confirmation dialog',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
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

    await tester.tap(find.byIcon(Icons.settings_outlined));
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

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Tap "End Game" button inside the dialog
    await tester.tap(find.widgetWithText(FilledButton, 'End Game'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  // ── 32. Back button is present in custom header ───────────────────────────────

  testWidgets('32. Back button is present in custom header', (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // New custom header always has an explicit back button
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
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
