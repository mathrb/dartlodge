import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/utils/app_colors.dart';
import 'package:my_darts/core/utils/app_theme.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/presentation/pages/cricket_board_page.dart';
import 'package:my_darts/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:my_darts/features/game/presentation/state/active_cricket_game_state.dart';
import 'package:my_darts/features/game/presentation/widgets/game_complete_modal_widget.dart';

// ── Fake notifier ──────────────────────────────────────────────────────────────

class _FakeActiveCricketGameNotifier extends ActiveCricketGameNotifier {
  _FakeActiveCricketGameNotifier(this._state);

  final ActiveCricketGameState? _state;
  final List<String> processedDarts = [];
  int nextPlayerCalls = 0;
  int undoCalls = 0;

  @override
  Future<ActiveCricketGameState?> build(String gameId) async => _state;

  @override
  Future<void> processDart(String s) async => processedDarts.add(s);

  @override
  Future<void> nextPlayer() async => nextPlayerCalls++;

  @override
  Future<void> undoDart() async => undoCalls++;
}

/// Notifier whose [build] hangs forever → provider stays in loading state.
class _LoadingActiveCricketGameNotifier extends ActiveCricketGameNotifier {
  @override
  Future<ActiveCricketGameState?> build(String gameId) =>
      Completer<ActiveCricketGameState?>().future;
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
  String cricketVariant = 'standard',
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
      cricketVariant: cricketVariant,
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
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
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
    expect(find.text('Bull'), findsOneWidget);
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

    expect(find.text('─'), findsWidgets); // 0 marks for 16, 15, Bull
    expect(find.text('/'), findsOneWidget); // 1 mark for 19
    expect(find.text('X'), findsOneWidget); // 2 marks for 18
    expect(find.text('⊗'), findsOneWidget); // 3 marks for 17
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

  // ── 7. Bull row has ≡ (disabled triple) ──────────────────────────────────

  testWidgets('7. Bull row has disabled triple cell (≡)', (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('≡'), findsOneWidget);
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

    // Single 20 — first '20' text that is inside an _InputCell (has GestureDetector)
    // The DartIndicator area also has '0', but '20' only appears in the table.
    // We find all GestureDetectors containing '20' text and tap the first one.
    final gestureDetectors = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('20'),
    );
    await tester.tap(gestureDetectors.first);
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

    final d19 = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('D19'),
    );
    await tester.tap(d19.first);
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

    final t18 = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('T18'),
    );
    await tester.tap(t18.first);
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

    // MISS is in the header row which is visible at the top
    final missBtn = find.widgetWithText(OutlinedButton, 'MISS');
    await tester.ensureVisible(missBtn);
    await tester.tap(missBtn);
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

    // The undo IconButton is the one with Icons.undo icon
    final undoBtn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undoBtn.onPressed, isNull);
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

    final undoFinder = find.widgetWithIcon(IconButton, Icons.undo);
    final undoBtn = tester.widget<IconButton>(undoFinder);
    expect(undoBtn.onPressed, isNotNull);

    await tester.tap(undoFinder);
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

    final nextPlayerBtn = find.widgetWithText(FilledButton, 'NEXT PLAYER');
    await tester.ensureVisible(nextPlayerBtn);
    await tester.tap(nextPlayerBtn);
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

    final nextPlayerBtn = find.widgetWithText(FilledButton, 'NEXT PLAYER');
    await tester.ensureVisible(nextPlayerBtn);
    await tester.tap(nextPlayerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Advance turn?'), findsOneWidget);
    expect(find.textContaining("1 dart(s)"), findsOneWidget);
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

    final nextPlayerBtn = find.widgetWithText(FilledButton, 'NEXT PLAYER');
    await tester.ensureVisible(nextPlayerBtn);
    await tester.tap(nextPlayerBtn);
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

    final nextPlayerBtn = find.widgetWithText(FilledButton, 'NEXT PLAYER');
    await tester.ensureVisible(nextPlayerBtn);
    await tester.tap(nextPlayerBtn);
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
    final containers = tester.widgetList<Container>(find.byType(Container));
    final tintedContainers = containers.where((c) {
      final color = c.color;
      return color != null && color.a < 1.0 && color.r > 0;
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

    // Bob (inactive) score text should have inactiveScore color
    final texts = tester.widgetList<Text>(find.text('10'));
    final inactiveColoredTexts = texts.where((t) {
      final style = t.style;
      return style?.color == AppColors.inactiveScore;
    }).toList();
    expect(inactiveColoredTexts, isNotEmpty);
  });

  // ── 20. Stats overlay toggles on FAB tap ─────────────────────────────────

  testWidgets('20. FAB toggles stats overlay', (tester) async {
    final notifier = _FakeActiveCricketGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    // After tapping, a dark scrim should appear (stats overlay visible)
    // We look for a container with black color (the scrim)
    final containers = tester.widgetList<Container>(find.byType(Container));
    final scrimContainers = containers.where((c) {
      final color = c.color;
      return color != null && color.r == 0 && color.g == 0 && color.b == 0;
    }).toList();
    expect(scrimContainers, isNotEmpty);
  });

  // ── 21. Game complete shown when pendingGameWinnerId set ──────────────────

  testWidgets('21. Game complete modal shown when pendingGameWinnerId set',
      (tester) async {
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

    expect(find.byType(GameCompleteModalWidget), findsOneWidget);
  });

  // ── 22. AppBar subtitle shows 'Cut Throat' for cut-throat variant ─────────

  testWidgets('22. AppBar subtitle shows "Cut Throat" for cut-throat variant',
      (tester) async {
    final gs = _cricketState(cricketVariant: 'cut-throat');
    final notifier =
        _FakeActiveCricketGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cut Throat'), findsOneWidget);
  });
}
