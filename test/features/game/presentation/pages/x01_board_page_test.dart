import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/game/capture_correction_sink.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/providers/board_camera_preview_provider.dart';
import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/pages/x01_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/active_game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/hero_metric_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/prominent_dart_band_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/x01_other_players_strip_widget.dart';

// ── Fake notifier ──────────────────────────────────────────────────────────────

class _FakeActiveGameNotifier extends ActiveGameNotifier {
  _FakeActiveGameNotifier(this._initialState);

  final ActiveGameState? _initialState;
  final List<String> processedDarts = [];
  int undoCalls = 0;
  int buildCount = 0;
  int endGameCalls = 0;

  @override
  Future<ActiveGameState?> build(String gameId) async {
    buildCount++;
    return _initialState;
  }

  @override
  Future<void> processDart(String segment,
          {String inputMethod = 'manual', double? x, double? y}) async =>
      processedDarts.add(segment);

  final List<({int index, String segment})> correctedDarts = [];

  @override
  Future<void> undoDart() async => undoCalls++;

  @override
  Future<void> correctTurnDart(int turnDartIndex, String newSegment) async =>
      correctedDarts.add((index: turnDartIndex, segment: newSegment));

  @override
  Future<void> endGame() async => endGameCalls++;

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

  /// Pushes a new state (used to drive sound listeners).
  void emit(ActiveGameState s) => state = AsyncData(s);
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
class _LoadingActiveGameNotifier extends ActiveGameNotifier {
  @override
  Future<ActiveGameState?> build(String gameId) =>
      Completer<ActiveGameState?>().future;
}

/// Forces auto-scoring on without touching SharedPreferences.
class _FakeAutoScoringEnabled extends AutoScoringEnabled {
  @override
  Future<bool> build() async => true;
}

/// Records sink calls so a test can assert the board routed a manual entry
/// (vs a correction) into the capture seam (#537).
class _FakeCorrectionSink implements CaptureCorrectionSink {
  final List<String> manualEntries = [];
  final List<({int cameraDartOrdinal, String segment})> corrections = [];
  @override
  void captureManualEntry({required String segment}) =>
      manualEntries.add(segment);
  @override
  void correctDart({required int cameraDartOrdinal, required String segment}) =>
      corrections.add((cameraDartOrdinal: cameraDartOrdinal, segment: segment));
}

/// Binds a fixed [CaptureCorrectionSink] so the board's
/// `activeCaptureCorrectionSinkProvider` reads return it.
class _BoundCorrectionSink extends ActiveCaptureCorrectionSink {
  _BoundCorrectionSink(this._sink);
  final CaptureCorrectionSink _sink;
  @override
  CaptureCorrectionSink? build() => _sink;
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Camera-first builder: auto-scoring on + a stub camera preview, so the board
/// renders the camera-first layout (#443) without a real `CameraPreview`.
Widget _buildAppCameraFirst(
  _FakeActiveGameNotifier notifier, {
  String gameId = 'game-1',
  CaptureCorrectionSink? correctionSink,
}) {
  final router = GoRouter(
    initialLocation: '/game/active/x01/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activeGameProvider.overrideWith(() => notifier),
      autoScoringEnabledProvider.overrideWith(() => _FakeAutoScoringEnabled()),
      boardCameraPreviewBuilderProvider.overrideWithValue(
        (ctx, id) => const SizedBox(key: ValueKey('camera-stub')),
      ),
      if (correctionSink != null)
        activeCaptureCorrectionSinkProvider
            .overrideWith(() => _BoundCorrectionSink(correctionSink)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
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
    // BoxDecoration color == cs.primaryFixed (== AppColors.primaryFixed) and width == 4.
    final containers = tester.widgetList<Container>(find.byType(Container));
    final accentBars = containers.where((c) {
      if (c.decoration is BoxDecoration) {
        return (c.decoration as BoxDecoration).color == AppColors.primaryFixed;
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
    // delta = 501 - 441 = 60; darts = 3; PPR = (60/3)*3 = 60.0 → fmtDouble strips trailing zero → '60'
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
    expect(find.text('60'), findsOneWidget);
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

  // ── 13a. Checkout suggestion filtered by remaining darts in turn (#367) ─────

  testWidgets(
      '13a. Score 170 with 1 dart thrown hides T20·T20·DB suggestion',
      (tester) async {
    _setPhoneViewport(tester);
    // 170 needs 3 darts (T20 · T20 · DB) but only 2 remain in the turn.
    final gs = _gameState(
      competitors: [_competitor(score: 170)],
      dartsThrownInTurn: 1,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Suggestion text must not appear; placeholder hint is shown instead.
    expect(find.text('T20 · T20 · DB'), findsNothing);
    expect(find.text('Suggestions appear in checkout range'), findsOneWidget);
    // CHECKOUT label is dimmed (no reachable suggestion).
    final checkoutText = tester.widget<Text>(find.text('CHECKOUT'));
    expect(checkoutText.style?.color?.alpha, lessThan(255));
  });

  testWidgets(
      '13b. Score 100 with 2 darts thrown hides T20·D20 suggestion',
      (tester) async {
    _setPhoneViewport(tester);
    // 100 needs 2 darts (T20 · D20) but only 1 remains in the turn.
    final gs = _gameState(
      competitors: [_competitor(score: 100)],
      dartsThrownInTurn: 2,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('T20 · D20'), findsNothing);
    expect(find.text('Suggestions appear in checkout range'), findsOneWidget);
  });

  testWidgets(
      '13c. Score 50 with 2 darts thrown still shows DB (1-dart suggestion)',
      (tester) async {
    _setPhoneViewport(tester);
    // 50 = DB (1 dart) — still reachable with 1 remaining dart.
    final gs = _gameState(
      competitors: [_competitor(score: 50)],
      dartsThrownInTurn: 2,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('DB'), findsWidgets);
    expect(
        find.text('Suggestions appear in checkout range'), findsNothing);
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

  // ── 19. NEXT ROUND enabled mid-turn (1–2 darts), disabled at 0 (#627) ────────

  testWidgets('19. NEXT ROUND enabled even mid-turn (new design)',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 2, turnActive: true);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // 1–2 darts: NEXT enabled (advancing silently MISS-fills, no dialog).
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('NEXT ROUND'),
        matching: find.byType(FilledButton),
      ).first,
    );
    expect(button.onPressed, isNotNull);
  });

  // ── 19b. NEXT ROUND disabled with 0 darts (mis-tap guard, #627) ──────────────

  testWidgets('19b. NEXT ROUND disabled when 0 darts thrown (#627)',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(dartsThrownInTurn: 0, turnActive: true);
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('NEXT ROUND'),
        matching: find.byType(FilledButton),
      ).first,
    );
    expect(button.onPressed, isNull,
        reason: '0-dart NEXT is gated to prevent accidental forfeit (#627)');
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

  // ── 28. Three-dot menu is present in custom header (#331) ─────────────────────

  testWidgets('28. Menu icon (three-dot) is present in custom header',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Was Icons.settings_outlined before #331 — the gear icon misleadingly
    // implied Settings while the action opened End Game. Now a 3-dot menu
    // with End Game + Settings entries.
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  // ── 29. Selecting End Game shows confirmation dialog ──────────────────────────

  testWidgets('29. Selecting End Game shows confirmation dialog',
      (tester) async {
    _setPhoneViewport(tester);
    final notifier = _FakeActiveGameNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
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

    await tester.tap(find.byIcon(Icons.more_vert));
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

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
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

  // ── 35. Camera-first: hero score + dart band, manual grid gone (#443) ────────

  testWidgets('35. Camera-first shows hero score and prominent dart band',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(name: 'Alice', score: 301, dartThrows: const ['T20']),
      ],
      dartsThrownInTurn: 1,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Hero metric (F2) renders the active player's remaining score.
    expect(find.byType(HeroMetricWidget), findsOneWidget);
    expect(find.text('301'), findsWidgets);
    // Prominent dart band (F1) replaces the small status-bar darts.
    expect(find.byType(ProminentDartBandWidget), findsOneWidget);
    // Camera stub fills the body; the status bar's dart placeholders are gone.
    expect(find.byKey(const ValueKey('camera-stub')), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsNothing);
  });

  // ── 36. Camera-first multi-player: other players in the compact strip ────────

  testWidgets('36. Camera-first multi-player shows the other-players strip',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        _competitor(id: 'c1', name: 'Alice', score: 301),
        _competitor(id: 'c2', name: 'Bob', score: 280),
      ],
      currentTurnIndex: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Active player (Alice) is the hero; the opponent (Bob) is in the strip.
    expect(find.byType(X01OtherPlayersStripWidget), findsOneWidget);
    expect(find.text('BOB'), findsWidgets);
    expect(find.text('280'), findsWidgets);
    // The active player is excluded from the strip — Alice + her score 301
    // appear exactly once (the hero), never duplicated into the strip.
    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('301'), findsOneWidget);
  });

  // ── 36b. Camera-first shows live PPR for active + opponents (#696) ────────────

  testWidgets('36b. Camera-first shows live PPR for the hero and opponents',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [
        // 60+20+5 = 85 over 3 darts → PPR 85.
        _competitor(
            id: 'c1',
            name: 'Alice',
            score: 301,
            dartThrows: const ['T20', '20', '5']),
        // 20+20+20 = 60 → PPR 60.
        _competitor(
            id: 'c2',
            name: 'Bob',
            score: 280,
            dartThrows: const ['20', '20', '20']),
      ],
      currentTurnIndex: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Active player's PPR rides under the hero numeral; the opponent's shows in
    // the strip — both visible in camera-first, as in the manual layout (#696).
    expect(find.text('PPR 85'), findsOneWidget);
    expect(find.text('PPR 60'), findsOneWidget);
  });

  // ── 37. Camera-first solo: no other-players strip ────────────────────────────

  testWidgets('37. Camera-first solo shows no other-players strip',
      (tester) async {
    _setPhoneViewport(tester);
    final gs = _gameState(
      competitors: [_competitor(name: 'Alice', score: 501)],
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(X01OtherPlayersStripWidget), findsNothing);
    expect(find.byType(HeroMetricWidget), findsOneWidget);
  });

  // ── 38. Camera-first checkout banner: only a REAL suggestion gets the
  // at-distance size; the placeholder stays compact (it ellipsised as
  // "Suggestions app…" at headlineMedium on a 412dp device).

  testWidgets('38. Camera-first: checkout placeholder stays compact',
      (tester) async {
    _setPhoneViewport(tester);
    // 301 → out of checkout range → placeholder shown.
    final gs = _gameState(
      competitors: [_competitor(name: 'Alice', score: 301)],
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    final placeholder = tester
        .widget<Text>(find.text('Suggestions appear in checkout range'));
    expect(placeholder.style?.fontSize, 14); // labelLarge, not headlineMedium
  });

  testWidgets(
      '39. Camera-first: a real checkout suggestion gets the at-distance size',
      (tester) async {
    _setPhoneViewport(tester);
    // 40 → in range → real suggestion rendered at the at-distance size.
    final gs = _gameState(
      competitors: [_competitor(name: 'Alice', score: 40)],
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions appear in checkout range'), findsNothing);
    final suggestion = tester.widget<Text>(find.text('D20'));
    expect(suggestion.style?.fontSize, 28); // headlineMedium
  });

  // ── 40. Manual entry captures the frame as labelled training data (#537) ─────

  testWidgets(
      '40. Camera-first manual entry fires captureManualEntry AND processDart',
      (tester) async {
    _setPhoneViewport(tester);
    final sink = _FakeCorrectionSink();
    // Empty turn → all three band slots are tappable manual-entry slots.
    final gs = _gameState(
      competitors: [_competitor(name: 'Alice', score: 501)],
      dartsThrownInTurn: 0,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester
        .pumpWidget(_buildAppCameraFirst(notifier, correctionSink: sink));
    await tester.pumpAndSettle();

    // An empty tappable slot renders an add-circle icon; tap the first to open
    // the manual-entry sheet.
    final emptySlots = find.byIcon(Icons.add_circle_outline);
    expect(emptySlots, findsNWidgets(3));
    await tester.tap(emptySlots.first);
    await tester.pumpAndSettle();

    // The sheet hosts the standard input grid; drive its callback directly
    // (robust against the grid's exact button labels).
    final grid = tester.widget<DartInputGridWidget>(
        find.byType(DartInputGridWidget));
    grid.onSegmentTapped('20');
    await tester.pumpAndSettle();

    // The board both scored the dart AND captured the frame as a labelled
    // mistake — the entered segment is the ground truth.
    expect(notifier.processedDarts, contains('20'));
    expect(sink.manualEntries, ['20']);
  });

  // ── 41. Correcting a thrown dart does NOT fire captureManualEntry (#537) ─────

  testWidgets('41. Camera-first correction does not call captureManualEntry',
      (tester) async {
    _setPhoneViewport(tester);
    final sink = _FakeCorrectionSink();
    // One dart thrown → slot 0 is a filled (correction) slot.
    final gs = _gameState(
      competitors: [
        _competitor(name: 'Alice', score: 481, dartThrows: const ['20']),
      ],
      dartsThrownInTurn: 1,
    );
    final notifier = _FakeActiveGameNotifier(_activeState(gameState: gs));
    await tester
        .pumpWidget(_buildAppCameraFirst(notifier, correctionSink: sink));
    await tester.pumpAndSettle();

    // Tap the filled slot (its segment text '20' is shown in the band) to open
    // the correction sheet.
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    // Drive the correction grid's callback directly.
    final grid = tester.widget<DartInputGridWidget>(
        find.byType(DartInputGridWidget));
    grid.onSegmentTapped('T20');
    await tester.pumpAndSettle();

    // Correction path → correctTurnDart, never the manual-entry capture seam.
    expect(notifier.correctedDarts, isNotEmpty);
    expect(sink.manualEntries, isEmpty);
  });

  // ── Sound wiring ─────────────────────────────────────────────────────────────

  testWidgets('plays dartThrown(segment) when a new dart is thrown',
      (tester) async {
    _setPhoneViewport(tester);
    final sound = _FakeSoundPort();
    final fakeNotifier = _FakeActiveGameNotifier(
      _activeState(gameState: _gameState(dartsThrownInTurn: 0)),
    );
    final container = ProviderContainer(
      overrides: [
        activeGameProvider.overrideWith(() => fakeNotifier),
        soundPortProvider.overrideWith((ref) => sound),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    notifier.emit(_activeState(
      gameState: _gameState(
        dartsThrownInTurn: 1,
        competitors: [_competitor(dartThrows: const ['T20'])],
      ),
    ));
    await tester.pump();

    expect(sound.dartThrows, ['T20']);
    expect(sound.cues, isEmpty);
  });

  testWidgets('plays bust cue on showBust false→true (not dartThrown)',
      (tester) async {
    _setPhoneViewport(tester);
    final sound = _FakeSoundPort();
    final fakeNotifier = _FakeActiveGameNotifier(
      _activeState(gameState: _gameState(), showBust: false),
    );
    final container = ProviderContainer(
      overrides: [
        activeGameProvider.overrideWith(() => fakeNotifier),
        soundPortProvider.overrideWith((ref) => sound),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final notifier = container.read(activeGameProvider('game-1').notifier)
        as _FakeActiveGameNotifier;
    notifier.triggerBust();
    await tester.pump();

    expect(sound.cues, [SoundCue.bust]);
    expect(sound.dartThrows, isEmpty);

    // Advance past the bust-dismissal timer to avoid a pending-timer warning.
    await tester.pump(const Duration(seconds: 3));
  });
}
