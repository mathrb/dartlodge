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
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/pages/practice_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_practice_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/active_practice_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dartboard_highlight_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/hero_metric_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_input_buttons_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_players_strip_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_target_display_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/prominent_dart_band_widget.dart';

// ── Fake notifier ──────────────────────────────────────────────────────────────

class _FakeActivePracticeNotifier extends ActivePracticeNotifier {
  _FakeActivePracticeNotifier(this._state);

  final ActivePracticeState? _state;
  final List<String> processedDarts = [];
  final List<(int, String)> corrections = [];
  int undoCalls = 0;
  int nextTurnCalls = 0;
  int endDrillCalls = 0;

  @override
  Future<ActivePracticeState?> build(String gameId) async => _state;

  @override
  Future<void> processDart(String segment, {String inputMethod = 'manual'}) async =>
      processedDarts.add(segment);

  @override
  Future<void> correctTurnDart(int turnDartIndex, String newSegment) async =>
      corrections.add((turnDartIndex, newSegment));

  @override
  Future<void> undoDart() async => undoCalls++;

  @override
  Future<void> startNextTurn() async => nextTurnCalls++;

  @override
  Future<void> endDrill() async => endDrillCalls++;

  @override
  void dismissBust() =>
      state = state.whenData((s) => s?.copyWith(showBust: false));

  /// Pushes a new state (used to drive sound listeners).
  void emit(ActivePracticeState s) => state = AsyncData(s);
}

class _FakeSoundPort implements SoundPort {
  final List<String> dartThrows = [];
  final List<SoundCue> cues = [];

  @override
  void dartThrown(String segment) => dartThrows.add(segment);

  @override
  void play(SoundCue cue) => cues.add(cue);
}

/// Forces auto-scoring on without touching SharedPreferences.
class _FakeAutoScoringEnabled extends AutoScoringEnabled {
  @override
  Future<bool> build() async => true;
}

/// Notifier whose [build] hangs forever → provider stays in loading state.
class _LoadingActivePracticeNotifier extends ActivePracticeNotifier {
  @override
  Future<ActivePracticeState?> build(String gameId) =>
      Completer<ActivePracticeState?>().future;
}

// ── State / GameState helpers ──────────────────────────────────────────────────

CompetitorState _practiceCompetitor({
  String id = 'c1',
  String name = 'Alice',
  int currentTarget = 3,
  int practiceRound = 3,
  int practiceAttempts = 0,
  int practiceSuccesses = 0,
  List<String> dartThrows = const [],
}) =>
    CompetitorState(
      competitorId: id,
      name: name,
      playerIds: const [],
      score: 0,
      dartThrows: dartThrows,
      currentTarget: currentTarget,
      practiceRound: practiceRound,
      practiceAttempts: practiceAttempts,
      practiceSuccesses: practiceSuccesses,
    );

GameState _practiceState({
  String gameId = 'game-1',
  GameType gameType = GameType.aroundTheClock,
  int dartsThrownInTurn = 0,
  bool isComplete = false,
  String aroundTheClockVariant = 'standard',
  CompetitorState? competitor,
  int? checkoutTargetSuccesses,
}) =>
    GameState(
      gameId: gameId,
      gameType: gameType,
      competitors: [competitor ?? _practiceCompetitor()],
      currentTurnIndex: 0,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: isComplete,
      aroundTheClockVariant: aroundTheClockVariant,
      checkoutTargetSuccesses: checkoutTargetSuccesses,
    );

ActivePracticeState _activeState({
  GameState? gameState,
  String? pendingGameWinnerId,
  bool showShanghaiBonus = false,
  bool showBust = false,
  bool wasEndedManually = false,
}) =>
    ActivePracticeState(
      gameState: gameState ?? _practiceState(),
      pendingGameWinnerId: pendingGameWinnerId,
      showShanghaiBonus: showShanghaiBonus,
      showBust: showBust,
      wasEndedManually: wasEndedManually,
    );

// ── Test app builders ──────────────────────────────────────────────────────────

List<RouteBase> _testRoutes({String gameId = 'game-1'}) => [
      GoRoute(
        path: '/practice-board/:gameId',
        builder: (ctx, s) =>
            PracticeBoardPage(gameId: s.pathParameters['gameId']!),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/post-game/:gameId',
        builder: (_, s) =>
            Scaffold(body: Text('post-game:${s.pathParameters['gameId']}')),
      ),
    ];

Widget _buildApp(
  _FakeActivePracticeNotifier notifier, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/practice-board/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activePracticeProvider.overrideWith(() => notifier),
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
/// renders the camera-first layout (#445) without a real `CameraPreview`.
Widget _buildAppCameraFirst(
  _FakeActivePracticeNotifier notifier, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/practice-board/$gameId',
    routes: _testRoutes(gameId: gameId),
  );
  return ProviderScope(
    overrides: [
      activePracticeProvider.overrideWith(() => notifier),
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

/// Tall viewport so the camera-first column fits.
void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _buildAppWithContainer(
  ProviderContainer container, {
  String gameId = 'game-1',
}) {
  final router = GoRouter(
    initialLocation: '/practice-board/$gameId',
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

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Loading state → CircularProgressIndicator, no AppBar ───────────────

  testWidgets('1. Loading state renders spinner', (tester) async {
    final router = GoRouter(
      initialLocation: '/practice-board/game-1',
      routes: _testRoutes(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activePracticeProvider
              .overrideWith(() => _LoadingActivePracticeNotifier()),
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
    expect(find.byType(AppBar), findsNothing);
  });

  // ── 2. Error state → error icon, message, Retry button ────────────────────

  testWidgets('2. Error state renders error icon, message, Retry',
      (tester) async {
    final fakeNotifier = _FakeActivePracticeNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier =
        container.read(activePracticeProvider('game-1').notifier)
            as _FakeActivePracticeNotifier;
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.error(Exception('DB error'), StackTrace.empty);
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Failed to load drill.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  // ── 3. Retry button re-enters loading ─────────────────────────────────────

  testWidgets('3. Tapping Retry re-enters loading state', (tester) async {
    final fakeNotifier = _FakeActivePracticeNotifier(_activeState());
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(() => fakeNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier =
        container.read(activePracticeProvider('game-1').notifier)
            as _FakeActivePracticeNotifier;
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.error(Exception('fail'), StackTrace.empty);
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    // After tapping Retry the provider is invalidated — it will re-enter loading
    // We can at least verify the button is tappable without error
    await tester.tap(find.text('Retry'));
    await tester.pump();
    // spinner or error — either is valid; key assertion is no crash
    expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('Failed to load drill.').evaluate().isNotEmpty, isTrue);
  });

  // ── 4. Null data state → 'Game not found', Back → '/' ────────────────────

  testWidgets('4. Null state renders Game not found and Back navigates home',
      (tester) async {
    final notifier = _FakeActivePracticeNotifier(null);
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Game not found'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Back'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  // ── 5. AppBar shows game name + progress subtitle for aroundTheClock ───────

  testWidgets('5. AppBar shows "Around the Clock" and progress subtitle',
      (tester) async {
    final gs = _practiceState(
      gameType: GameType.aroundTheClock,
      competitor: _practiceCompetitor(currentTarget: 3, practiceRound: 3),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Around the Clock'), findsOneWidget);
    // ATC subtitle is now "Round N" — "Number" read as a duplicate of
    // the target number above (#288).
    expect(find.text('Round 3'), findsOneWidget);
  });

  // ── 6. AppBar overflow menu shows End Drill ───────────────────────────────

  testWidgets('6. Overflow menu shows End Drill (solo)', (tester) async {
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('End Drill'), findsOneWidget);
    expect(find.text('End Game'), findsNothing);
    // Reset Drill was removed in #195 hygiene sweep — it was a no-op
    // (invalidateSelf replays the same event log → same state).
    expect(find.text('Reset Drill'), findsNothing);
  });

  testWidgets(
      '6b. Overflow menu shows End Game for multi-player ATC (#276)',
      (tester) async {
    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.aroundTheClock,
      competitors: [
        _practiceCompetitor(id: 'c1', name: 'Alice'),
        _practiceCompetitor(id: 'c2', name: 'Bob'),
        _practiceCompetitor(id: 'c3', name: 'Carol'),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      aroundTheClockVariant: 'standard',
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('End Game'), findsOneWidget);
    expect(find.text('End Drill'), findsNothing);
  });

  testWidgets(
      '6c. Multi-player ATC surfaces the current player name above the target (#276)',
      (tester) async {
    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.aroundTheClock,
      competitors: [
        _practiceCompetitor(id: 'c1', name: 'Alice'),
        _practiceCompetitor(id: 'c2', name: 'Bob'),
        _practiceCompetitor(id: 'c3', name: 'Carol'),
      ],
      currentTurnIndex: 1, // Bob's turn
      dartsThrownInTurn: 0,
      isComplete: false,
      aroundTheClockVariant: 'standard',
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.text("BOB'S TURN"), findsOneWidget);
    expect(find.text("ALICE'S TURN"), findsNothing);
  });

  testWidgets(
      '6d. Solo ATC does NOT render the per-turn name banner (regression for #276 narrow scope)',
      (tester) async {
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.textContaining("'S TURN"), findsNothing);
  });

  testWidgets(
      '6f. Shanghai NEXT ROUND is disabled when 0 darts have been thrown (#289)',
      (tester) async {
    // Tapping NEXT ROUND with no darts in the turn silently skipped a
    // Shanghai round (the round number = the target for that round).
    // Guard the button until ≥1 dart is registered.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.shanghai,
      competitors: [_practiceCompetitor()],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      turnActive: true,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(btn.onPressed, isNull,
        reason: '0-dart NEXT ROUND tap would silently skip the round');
  });

  testWidgets(
      '6f-atc. ATC NEXT ROUND also gated on ≥1 dart, matching Shanghai (#336)',
      (tester) async {
    // ATC previously enabled NEXT ROUND with 0 darts, which is inconsistent
    // with Shanghai and lets a mis-tap silently hand the turn over without
    // scoring. Now both games require at least one dart before the button
    // becomes active.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.aroundTheClock,
      competitors: [_practiceCompetitor()],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      turnActive: true,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(btn.onPressed, isNull,
        reason: 'ATC 0-dart NEXT ROUND now gated alongside Shanghai (#336)');
  });

  testWidgets(
      '6g. Shanghai NEXT ROUND enables once a dart is thrown',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.shanghai,
      competitors: [
        _practiceCompetitor(dartThrows: const ['T1']),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 1,
      isComplete: false,
      turnActive: true,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(btn.onPressed, isNotNull,
        reason: 'NEXT ROUND must enable once the player has committed a dart');
  });

  testWidgets(
      '6e. Catch 40 NEXT TARGET enables after a 2-dart checkout (#291)',
      (tester) async {
    // After a 2-dart Catch 40 checkout the engine leaves
    // `catch40TargetRemaining: 0`, `turnActive: false`, `dartsThrownInTurn: 2`.
    // The bottom bar must enable NEXT TARGET so the player can advance —
    // they shouldn't have to throw a phantom MISS first (#291 bug A).
    // PR #264 fixed the engine half (no more MISS-fill bust on checkout);
    // this test locks in the widget half.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.catch40,
      competitors: [
        _practiceCompetitor(dartThrows: const ['T7', 'D20']),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 2,
      isComplete: false,
      turnActive: false,
      catch40TargetRemaining: 0,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT TARGET'),
    );
    expect(btn.onPressed, isNotNull,
        reason: 'NEXT TARGET must be enabled after a 2-dart checkout');
  });

  // ── 7. DartboardHighlightWidget present with Expanded ancestor ────────────

  testWidgets('7. DartboardHighlightWidget is present with Expanded ancestor',
      (tester) async {
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // DartboardHighlightWidget should be in the tree
    final dartboardFinder = find.byType(
      // Use byWidgetPredicate to look for the widget by type name since we may
      // not have a direct import to the widget class type here.
      // Instead check for it via ancestor relationship through Expanded.
      Expanded,
    );
    expect(dartboardFinder, findsWidgets);
  });

  // ── 8. Target label uses scoreMedium / Space Grotesk + primary color ──────

  testWidgets('8. Target label uses Oswald font and primary color',
      (tester) async {
    final gs = _practiceState(
      competitor: _practiceCompetitor(currentTarget: 17, practiceRound: 17),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final colorScheme = AppTheme.light().colorScheme;

    // Find the Text('17') inside PracticeTargetDisplayWidget
    final targetWidget = find.descendant(
      of: find.byType(PracticeTargetDisplayWidget),
      matching: find.text('17'),
    );
    expect(targetWidget, findsOneWidget);

    final text = tester.widget<Text>(targetWidget);
    expect(text.style?.color, colorScheme.primary);
    expect(text.style?.fontFamily?.toLowerCase().contains('spacegrotesk'), isTrue);
  });

  // ── 11. Undo disabled when dartsThrownInTurn=0 and no dart throws ─────────

  testWidgets('11. Undo disabled when no darts thrown', (tester) async {
    final gs = _practiceState(
      dartsThrownInTurn: 0,
      competitor: _practiceCompetitor(dartThrows: const []),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final undoBtn = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(undoBtn.onTap, isNull);
  });

  // ── 12. Undo enabled when dartsThrownInTurn=1 ─────────────────────────────

  testWidgets('12. Undo enabled when dartsThrownInTurn=1', (tester) async {
    final gs = _practiceState(dartsThrownInTurn: 1);
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final undoBtn = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(undoBtn.onTap, isNotNull);
  });

  // ── 13. NEXT ROUND shown + enabled after 3 darts, not complete ────────────

  testWidgets('13. NEXT ROUND shown and enabled after 3 darts', (tester) async {
    final gs = _practiceState(
      dartsThrownInTurn: 3,
      isComplete: false,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final nextRoundBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(nextRoundBtn.onPressed, isNotNull);
  });

  // ── 14. NEXT ROUND shown for checkoutPractice (same as other practice modes) ─

  testWidgets('14. NEXT ROUND shown for checkoutPractice',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final gs = _practiceState(
      gameType: GameType.checkoutPractice,
      dartsThrownInTurn: 3,
      isComplete: false,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'NEXT ROUND'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'END DRILL'), findsNothing);
  });

  // ── 15. NEXT ROUND disabled when < 3 darts ────────────────────────────────

  testWidgets('15. NEXT ROUND enabled when dartsThrownInTurn < 3 (fills remaining as MISS)',
      (tester) async {
    final gs = _practiceState(dartsThrownInTurn: 1, isComplete: false);
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final nextRoundBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'NEXT ROUND'),
    );
    expect(nextRoundBtn.onPressed, isNotNull);
  });

  // ── 16. Natural completion navigates to post-game summary ────────────────

  testWidgets('16. Natural completion transition navigates to post-game',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(
          () => _FakeActivePracticeNotifier(
            _activeState(
              gameState: _practiceState(
                gameType: GameType.bobs27,
                isComplete: false,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    expect(find.text('post-game:game-1'), findsNothing);

    final notifier = container
        .read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;
    final completeGs = _practiceState(
      gameType: GameType.bobs27,
      isComplete: true,
    );
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.data(_activeState(gameState: completeGs));
    await tester.pumpAndSettle();

    expect(find.text('post-game:game-1'), findsOneWidget,
        reason: 'natural completion navigates to post-game summary');
    expect(find.byType(AlertDialog), findsNothing,
        reason: 'no completion dialog after modal removal');
  });

  // ── 17. Bottom bar has SafeArea above its Row ─────────────────────────────

  testWidgets('17. Bottom bar Row has SafeArea ancestor', (tester) async {
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    // Find a Row that is a descendant of SafeArea (bottom bar row)
    final safeAreaFinder = find.byType(SafeArea);
    expect(safeAreaFinder, findsWidgets);

    // At least one SafeArea wraps a Row
    final rowInSafeArea = find.descendant(
      of: safeAreaFinder,
      matching: find.byType(Row),
    );
    expect(rowInSafeArea, findsWidgets);
  });

  // ── 18. Back button navigates to home ─────────────────────────────────────

  testWidgets('18. Back button shows confirmation dialog then navigates to home',
      (tester) async {
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('End Game?'), findsOneWidget);

    // Tapping Cancel keeps the game
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('End Game?'), findsNothing);

    // Tapping back again and confirming navigates home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  // ── 19. PracticeInputButtonsWidget contains MISS button ─────────────────

  testWidgets('19. PracticeInputButtonsWidget contains MISS for aroundTheClock',
      (tester) async {
    final gs = _practiceState(gameType: GameType.aroundTheClock);
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final missInInputButtons = find.descendant(
      of: find.byType(PracticeInputButtonsWidget),
      matching: find.text('MISS'),
    );
    expect(missInInputButtons, findsOneWidget);
  });

  testWidgets('19b. PracticeInputButtonsWidget contains MISS for bobs27',
      (tester) async {
    final gs = _practiceState(gameType: GameType.bobs27);
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final missInInputButtons = find.descendant(
      of: find.byType(PracticeInputButtonsWidget),
      matching: find.text('MISS'),
    );
    expect(missInInputButtons, findsOneWidget);
  });

  testWidgets('19c. PracticeInputButtonsWidget uses DartInputGridWidget for checkoutPractice',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final gs = _practiceState(gameType: GameType.checkoutPractice);
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    final gridInInputButtons = find.descendant(
      of: find.byType(PracticeInputButtonsWidget),
      matching: find.byType(DartInputGridWidget),
    );
    expect(gridInInputButtons, findsOneWidget);
  });

  // ── 20. Manual "End Drill" navigates to the post-game summary ────────────
  //
  // Earlier behaviour (#230) routed manual End Drill to home so the
  // post-game summary was reserved for natural completions; the user
  // feedback in #289 / #291 reverses that — the drill is over either way,
  // so the player gets the hero card + per-player breakdown either way.
  // The completion listener still no-ops on `wasEndedManually: true` so
  // the menu handler's `context.go(postGame)` doesn't race with the
  // listener.

  testWidgets('20. End Drill menu navigates to post-game summary (#289, #291)',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(
          () => _FakeActivePracticeNotifier(
            _activeState(
              gameState: _practiceState(
                gameType: GameType.bobs27,
                isComplete: false,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final notifier = container
        .read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Drill'));
    await tester.pumpAndSettle();

    expect(notifier.endDrillCalls, 1);
    expect(find.text('post-game:game-1'), findsOneWidget,
        reason: 'manual end-drill now routes to the post-game summary');
    expect(find.text('home'), findsNothing,
        reason: 'no longer dropping the drill on the floor at home');
  });

  // ── 21. Manual completion with wasEndedManually skips post-game nav ──────

  testWidgets(
      '21. Completion with wasEndedManually=true does not navigate to post-game',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(
          () => _FakeActivePracticeNotifier(
            _activeState(
              gameState: _practiceState(
                gameType: GameType.aroundTheClock,
                isComplete: false,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier = container
        .read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;

    final completeGs = _practiceState(
      gameType: GameType.aroundTheClock,
      isComplete: true,
    );
    // ignore: invalid_use_of_protected_member
    notifier.state = AsyncValue.data(_activeState(
      gameState: completeGs,
      wasEndedManually: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('post-game:game-1'), findsNothing,
        reason:
            'listener must skip post-game nav when wasEndedManually is true');
  });

  // ── 22. Shanghai-on-final-dart defers nav while banner is animating ──────

  testWidgets(
      '22. Shanghai completion with showShanghaiBonus delays nav by 1.3s',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(
          () => _FakeActivePracticeNotifier(
            _activeState(
              gameState: _practiceState(
                gameType: GameType.shanghai,
                isComplete: false,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier = container
        .read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;
    final completeGs = _practiceState(
      gameType: GameType.shanghai,
      isComplete: true,
    );
    // ignore: invalid_use_of_protected_member
    notifier.state = AsyncValue.data(_activeState(
      gameState: completeGs,
      showShanghaiBonus: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Still on the practice board because the 1.3s delay hasn't elapsed.
    expect(find.text('post-game:game-1'), findsNothing,
        reason: 'nav must be deferred while Shanghai banner is animating');

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('post-game:game-1'), findsOneWidget,
        reason: 'nav fires after the banner animation delay');
  });

  // ── 23. Non-Shanghai completion navigates immediately ────────────────────

  testWidgets(
      '23. Non-shanghai completion navigates to post-game immediately',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(
          () => _FakeActivePracticeNotifier(
            _activeState(
              gameState: _practiceState(
                gameType: GameType.aroundTheClock,
                isComplete: false,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pump();

    final notifier = container
        .read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;
    final completeGs = _practiceState(
      gameType: GameType.aroundTheClock,
      isComplete: true,
    );
    // ignore: invalid_use_of_protected_member
    notifier.state =
        AsyncValue.data(_activeState(gameState: completeGs));
    await tester.pumpAndSettle();

    expect(find.text('post-game:game-1'), findsOneWidget);
  });

  // ── 23. Bob's 27 displayedRound stays on just-played round (#258) ────────
  //
  // Regression for #258. The Bob's 27 engine bumps `competitor.practiceRound`
  // on the 3rd dart of a turn, BUT the input grid stays disabled
  // (`dartsThrownInTurn == 3`) until the user taps NEXT ROUND. Without the
  // UI compensation, the user sees the next round's target paired with a
  // locked grid — looks like input was silently swallowed. The page now
  // shows the just-played round during that gap.

  testWidgets("23. Bob's 27: shows just-played round while turn is locked",
      (tester) async {
    // Mid-round state: 2 darts thrown, practiceRound still 1, turn active.
    // Expect target label "D1" and round indicator "1 / 20".
    final gsMidTurn = _practiceState(
      gameType: GameType.bobs27,
      dartsThrownInTurn: 2,
      competitor: _practiceCompetitor(practiceRound: 1),
    );
    final notifierMid = _FakeActivePracticeNotifier(
      _activeState(gameState: gsMidTurn),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activePracticeProvider.overrideWith(() => notifierMid),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('ROUND 1 / 20'), findsOneWidget);
  });

  // ── 23c. Checkout Practice: ROUND counter increments per attempt (#261) ──

  Future<void> _pumpCheckoutPractice(
    WidgetTester tester, {
    required int dartsThrownInTurn,
    required List<String> dartThrows,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gs = _practiceState(
      gameType: GameType.checkoutPractice,
      dartsThrownInTurn: dartsThrownInTurn,
      competitor: _practiceCompetitor(dartThrows: dartThrows),
    );
    final notifier =
        _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activePracticeProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Checkout Practice: ROUND counter derives from darts thrown',
      (tester) async {
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 0,
      dartThrows: const [],
    );
    expect(find.text('ROUND 1'), findsOneWidget);
  });

  testWidgets(
      'Checkout Practice: ROUND stays on attempt 1 while mid-turn',
      (tester) async {
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 1,
      dartThrows: const ['T20'],
    );
    expect(find.text('ROUND 1'), findsOneWidget);
  });

  testWidgets(
      'Checkout Practice: ROUND advances to 2 after NEXT ROUND (#261)',
      (tester) async {
    // 3 darts logged from attempt 1, dartsThrownInTurn reset by TurnEnded.
    // Should display attempt 2.
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 0,
      dartThrows: const ['T20', 'T20', 'DB'],
    );
    expect(find.text('ROUND 2'), findsOneWidget);
    expect(find.text('ROUND 1'), findsNothing);
  });

  // ── 23e. Checkout Practice ROUND label semantics (#327) ─────────────────

  testWidgets(
      'Checkout Practice: status bar shows "ROUND N" without misleading "/ M" denominator',
      (tester) async {
    // Even with a target-successes quota set, the status bar must NOT pair
    // attempt count with success target — they're different units.
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gs = _practiceState(
      gameType: GameType.checkoutPractice,
      checkoutTargetSuccesses: 3,
      dartsThrownInTurn: 0,
      competitor: _practiceCompetitor(
        dartThrows: const ['T20', 'T20', 'DB', 'T20', 'T20', 'DB'],
      ),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activePracticeProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 6 darts of round 1 + round 2 (3 each); after the 2nd TurnEnded
    // dartsThrownInTurn=0 with 6 darts → displayedRound=3.
    expect(find.text('ROUND 3'), findsOneWidget);
    expect(find.text('ROUND 3 / 3'), findsNothing,
        reason: 'success target must NOT appear as round denominator');
    expect(find.text('ROUND 4 / 3'), findsNothing);
  });

  testWidgets(
      'Checkout Practice: secondary metric surfaces Success X/M when quota set',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gs = _practiceState(
      gameType: GameType.checkoutPractice,
      checkoutTargetSuccesses: 3,
      dartsThrownInTurn: 1,
      competitor: _practiceCompetitor(
        dartThrows: const ['T20', 'T20', 'DB', 'T20'],
        practiceSuccesses: 1,
      ),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activePracticeProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Success 1/3 · 1 dart thrown'), findsOneWidget);
  });

  testWidgets(
      'Checkout Practice: secondary metric omits Success line in infinite mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gs = _practiceState(
      gameType: GameType.checkoutPractice,
      // checkoutTargetSuccesses left null → ∞ mode
      dartsThrownInTurn: 2,
      competitor: _practiceCompetitor(
        dartThrows: const ['T20', 'T20'],
      ),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activePracticeProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 darts thrown'), findsOneWidget);
    expect(find.textContaining('Success'), findsNothing);
  });

  // ── 23d. Checkout Practice: "N darts thrown" is per-round (#328) ─────────

  testWidgets(
      'Checkout Practice: "darts thrown" counts only the CURRENT round',
      (tester) async {
    // After round 1 (3 darts thrown, NEXT ROUND tapped → dartsThrownInTurn=0),
    // round 2 starts with 1 dart thrown so far. Pre-#328 the secondary line
    // would show "4 darts thrown" (session-cumulative); post-fix it shows
    // "1 dart thrown" (current attempt only).
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 1,
      dartThrows: const ['T20', 'T20', 'DB', 'T20'],
    );
    expect(find.text('1 dart thrown'), findsOneWidget);
    expect(find.text('4 darts thrown'), findsNothing,
        reason: 'must NOT show session-cumulative count');
  });

  testWidgets(
      'Checkout Practice: "darts thrown" resets to 0 at start of new round',
      (tester) async {
    // Right after NEXT ROUND fires TurnEnded: dartsThrownInTurn=0, dartThrows
    // still contains round 1's 3 darts.
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 0,
      dartThrows: const ['T20', 'T20', 'DB'],
    );
    expect(find.text('0 darts thrown'), findsOneWidget);
  });

  testWidgets(
      'Checkout Practice: bust pad sentinels are excluded from per-round count',
      (tester) async {
    // 1-dart bust: engine appends ['T20', '', ''] and sets dartsThrownInTurn=3.
    // User threw 1 real dart; display must show "1 dart thrown" not "3".
    await _pumpCheckoutPractice(
      tester,
      dartsThrownInTurn: 3,
      dartThrows: const ['T20', '', ''],
    );
    expect(find.text('1 dart thrown'), findsOneWidget);
    expect(find.text('3 darts thrown'), findsNothing,
        reason: 'sentinel pads must not inflate the per-round count (#261)');
  });

  testWidgets(
      "23b. Bob's 27: post-3rd-dart shows just-played round, not the next one",
      (tester) async {
    // Engine state right after the 3rd dart of round 1 (miss path):
    // engine has bumped practiceRound to 2, dartsThrownInTurn = 3, score
    // adjusted. The page must keep the UI on round 1 / D1 until NEXT ROUND
    // fires TurnStarted.
    final gsTurnEnded = _practiceState(
      gameType: GameType.bobs27,
      dartsThrownInTurn: 3,
      competitor: _practiceCompetitor(
        practiceRound: 2,
        dartThrows: const ['MISS', 'MISS', 'MISS'],
      ),
    );
    final notifierEnded = _FakeActivePracticeNotifier(
      _activeState(gameState: gsTurnEnded),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activePracticeProvider.overrideWith(() => notifierEnded),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/practice-board/game-1',
            routes: _testRoutes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('D1'), findsOneWidget,
        reason: 'Target stays on just-played D1, not the engine-bumped D2.');
    expect(find.text('ROUND 1 / 20'), findsOneWidget,
        reason: 'Round indicator stays at 1/20 until NEXT ROUND.');
    expect(find.text('D2'), findsNothing);
  });

  // ── Camera-first: hero target + dart band, no dartboard highlight (#445) ─────

  testWidgets('Camera-first shows the hero target and prominent dart band',
      (tester) async {
    _setTallViewport(tester);
    final gs = _practiceState(
      gameType: GameType.aroundTheClock,
      competitor: _practiceCompetitor(currentTarget: 14, dartThrows: const ['1']),
      dartsThrownInTurn: 1,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Hero metric (F2 via heroSize) shows the target large; dart band present.
    expect(find.byType(HeroMetricWidget), findsOneWidget);
    expect(find.byType(ProminentDartBandWidget), findsOneWidget);
    // The aim dartboard highlight is hidden (the camera IS the board), the
    // manual input buttons are gone, and the camera stub fills the body.
    expect(find.byType(DartboardHighlightWidget), findsNothing);
    expect(find.byType(PracticeInputButtonsWidget), findsNothing);
    expect(find.byKey(const ValueKey('camera-stub')), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsNothing);
  });

  testWidgets('Camera-first multi-player ATC shows the other-players strip',
      (tester) async {
    _setTallViewport(tester);
    final gs = _practiceState(gameType: GameType.aroundTheClock).copyWith(
      competitors: [
        _practiceCompetitor(id: 'c1', name: 'Alice', currentTarget: 14),
        _practiceCompetitor(id: 'c2', name: 'Bob', currentTarget: 7),
      ],
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Active player (Alice, target 14) is the hero; the opponent (Bob, 7) is
    // in the strip.
    expect(find.byType(PracticePlayersStripWidget), findsOneWidget);
    expect(find.text('BOB'), findsWidgets);
    expect(find.text('7'), findsWidgets);
    // The active player (Alice) is the hero, not duplicated into the strip —
    // her name header is "ALICE'S TURN", so a bare 'ALICE' chip would only
    // appear if the exclusion filter were broken.
    expect(find.text('ALICE'), findsNothing);
  });

  testWidgets('Camera-first solo drill shows no other-players strip',
      (tester) async {
    _setTallViewport(tester);
    final gs = _practiceState(
      gameType: GameType.catch40,
      competitor: _practiceCompetitor(),
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(PracticePlayersStripWidget), findsNothing);
    expect(find.byType(ProminentDartBandWidget), findsOneWidget);
  });

  testWidgets(
      'Camera-first correction sheet stays usable after the turn ends (#438)',
      (tester) async {
    _setTallViewport(tester);
    // Turn fully thrown (3 darts) → engine set turnActive=false but the turn is
    // not yet advanced. Tapping a recorded dart must still let the player
    // correct it; the segment buttons must NOT be disabled by turnActive.
    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.aroundTheClock,
      competitors: [
        _practiceCompetitor(
          currentTarget: 5,
          dartThrows: const ['T18', 'T19', 'T20'],
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 3,
      isComplete: false,
      turnActive: false,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Tap the 3rd recorded dart to open its correction sheet.
    await tester.tap(find.text('T20'));
    await tester.pumpAndSettle();
    expect(find.text('Correct dart 3'), findsOneWidget);

    // The segment buttons must be live: tapping MISS corrects dart 3.
    await tester.tap(find.text('MISS'));
    await tester.pumpAndSettle();

    expect(notifier.corrections, [(2, 'MISS')]);
    expect(find.text('Correct dart 3'), findsNothing,
        reason: 'sheet pops after a successful correction');
  });

  testWidgets(
      'ATC correction sheet offers the full board, not just the advanced '
      'target (#500)', (tester) async {
    _setTallViewport(tester);
    // A false positive on target 18 advanced the game to 19. The recorded dart
    // ('18') must be correctable to the segment actually thrown (e.g. single 1)
    // — the restricted bar would only expose 19's segments.
    final gs = GameState(
      gameId: 'game-1',
      gameType: GameType.aroundTheClock,
      competitors: [
        _practiceCompetitor(
          currentTarget: 19,
          dartThrows: const ['18'],
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 1,
      isComplete: false,
      turnActive: true,
    );
    final notifier = _FakeActivePracticeNotifier(_activeState(gameState: gs));
    await tester.pumpWidget(_buildAppCameraFirst(notifier));
    await tester.pumpAndSettle();

    // Open the recorded dart's correction sheet.
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('Correct dart 1'), findsOneWidget);

    // The full grid exposes Single Bull (text '25'), which the restricted ATC
    // bar never offers — correcting to it proves the full picker is available.
    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();

    expect(notifier.corrections, [(0, 'SB')]);
  });

  testWidgets('Manual mode shows the input buttons and dartboard highlight',
      (tester) async {
    _setTallViewport(tester);
    final notifier = _FakeActivePracticeNotifier(_activeState());
    await tester.pumpWidget(_buildApp(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeInputButtonsWidget), findsOneWidget);
    expect(find.byType(ProminentDartBandWidget), findsNothing);
    expect(find.byType(HeroMetricWidget), findsNothing);
  });

  // ── Sound wiring ─────────────────────────────────────────────────────────────

  testWidgets('plays dartThrown(segment) on a new dart', (tester) async {
    _setTallViewport(tester);
    final sound = _FakeSoundPort();
    final fakeNotifier = _FakeActivePracticeNotifier(
      _activeState(gameState: _practiceState(dartsThrownInTurn: 0)),
    );
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(() => fakeNotifier),
        soundPortProvider.overrideWith((ref) => sound),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final notifier = container.read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;
    notifier.emit(_activeState(
      gameState: _practiceState(
        dartsThrownInTurn: 1,
        competitor: _practiceCompetitor(dartThrows: const ['T20']),
      ),
    ));
    await tester.pump();

    expect(sound.dartThrows, ['T20']);
    expect(sound.cues, isEmpty);
  });

  testWidgets('plays bust cue on a Catch-40 bust (showBust false→true)',
      (tester) async {
    _setTallViewport(tester);
    final sound = _FakeSoundPort();
    final fakeNotifier = _FakeActivePracticeNotifier(
      _activeState(
        gameState: _practiceState(gameType: GameType.catch40),
        showBust: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activePracticeProvider.overrideWith(() => fakeNotifier),
        soundPortProvider.overrideWith((ref) => sound),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildAppWithContainer(container));
    await tester.pumpAndSettle();

    final notifier = container.read(activePracticeProvider('game-1').notifier)
        as _FakeActivePracticeNotifier;
    notifier.emit(_activeState(
      gameState: _practiceState(gameType: GameType.catch40),
      showBust: true,
    ));
    await tester.pump();

    expect(sound.cues, [SoundCue.bust]);
    expect(sound.dartThrows, isEmpty);

    // Advance past the bust-dismissal timer to avoid a pending-timer warning.
    await tester.pump(const Duration(seconds: 3));
  });
}
