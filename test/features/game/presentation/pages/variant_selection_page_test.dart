import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/game/presentation/pages/variant_selection_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakePlayerRepository implements PlayerRepository {
  @override
  Future<List<Player>> getAllPlayers() async => [];
  @override
  Future<Player?> getPlayer(String playerId) async => null;
  @override
  Future<void> createPlayer(Player player) async {}
  @override
  Future<void> updatePlayerName(String playerId, String name) async {}
  @override
  Future<void> touchPlayer(String playerId) async {}
  @override
  Future<void> deletePlayer(String playerId) async {}
  @override
  Stream<List<Player>> watchAllPlayers() => const Stream.empty();
}

/// Notifier override that starts in a fixed state (no init side-effects).
class _FixedGameSetupNotifier extends GameSetupNotifier {
  _FixedGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a testable app for [category] with optional [setupState].
/// Exposes [pushedRoutes] to verify navigation.
Widget _buildApp(
  String category, {
  GameSetupState? setupState,
  List<String>? pushedRoutes,
}) {
  final captured = pushedRoutes ?? [];
  final router = GoRouter(
    initialLocation: '/game/variant-selection/$category',
    routes: [
      GoRoute(
        path: '/game/variant-selection/:category',
        builder: (context, state) => VariantSelectionPage(
          category: state.pathParameters['category'] ?? category,
        ),
      ),
      GoRoute(
        path: '/game/player-selection',
        builder: (_, __) {
          captured.add('/game/player-selection');
          return const Scaffold(body: Text('player-selection'));
        },
      ),
    ],
  );

  final initialState = setupState ?? const GameSetupState.selectingType();

  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
      gameSetupProvider.overrideWith(() => _FixedGameSetupNotifier(initialState)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VariantSelectionPage — X01', () {
    testWidgets('renders 4 enabled rows and 1 disabled Custom row',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('501'), findsOneWidget);
      expect(find.text('301'), findsOneWidget);
      expect(find.text('701'), findsOneWidget);
      expect(find.text('901'), findsOneWidget);
      expect(find.text('CUSTOM', skipOffstage: false), findsOneWidget);

      // Custom row wrapped in Opacity(0.38)
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity, skipOffstage: false));
      expect(opacityWidgets.any((o) => o.opacity == 0.38), isTrue);
    });

    testWidgets('page title "X01" is displayed', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('X01'), findsOneWidget);
    });

    testWidgets('tapping 501 row navigates to /game/player-selection',
        (tester) async {
      final pushed = <String>[];
      await tester.pumpWidget(_buildApp('x01', pushedRoutes: pushed));
      await tester.pumpAndSettle();

      await tester.tap(find.text('501'));
      await tester.pumpAndSettle();

      expect(find.text('player-selection'), findsOneWidget);
    });

    testWidgets('Custom row shows Tooltip "Custom configuration coming soon"',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      final tooltip = find.byWidgetPredicate(
        (w) => w is Tooltip && w.message == 'Custom configuration coming soon',
        skipOffstage: false,
      );
      expect(tooltip, findsOneWidget);
    });

    testWidgets('disabled row has 38% opacity', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity, skipOffstage: false));
      expect(opacities.where((o) => o.opacity == 0.38), hasLength(1));
    });

    testWidgets('tapping disabled Custom row does not navigate', (tester) async {
      // Use a physically tall window so CUSTOM is on screen and tappable.
      tester.view.physicalSize = const Size(2400, 6000);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CUSTOM'));
      await tester.pumpAndSettle();

      expect(find.text('player-selection'), findsNothing);
    });
  });

  group('VariantSelectionPage — Cricket', () {
    testWidgets('renders 4 enabled rows and 1 disabled Custom', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.text('STANDARD'), findsOneWidget);
      expect(find.text('NO SCORE'), findsOneWidget);
      expect(find.text('CUT THROAT', skipOffstage: false), findsOneWidget);
      expect(find.text('TACTICS', skipOffstage: false), findsOneWidget);
      expect(find.text('CUSTOM', skipOffstage: false), findsOneWidget);
    });

    testWidgets('page title "Cricket" is displayed', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.text('CRICKET'), findsOneWidget);
    });
  });

  group('VariantSelectionPage — Practice', () {
    testWidgets('renders 5 enabled rows', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      expect(find.text('AROUND THE CLOCK'), findsOneWidget);
      expect(find.text('CATCH 40', skipOffstage: false), findsOneWidget);
      expect(find.text("BOB'S 27", skipOffstage: false), findsOneWidget);
      expect(find.text('SHANGHAI', skipOffstage: false), findsOneWidget);
      expect(find.text('170 CHECKOUT', skipOffstage: false), findsOneWidget);
    });

    testWidgets('no disabled rows in practice', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.where((o) => o.opacity == 0.38), isEmpty);
    });

    testWidgets('page title "Practice" is displayed', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      expect(find.text('PRACTICE'), findsOneWidget);
    });
  });

  group('VariantSelectionPage — page header', () {
    testWidgets('shows "GAME SELECTION" overline', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('GAME SELECTION'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('Select your match variation to begin'), findsOneWidget);
    });
  });
}
