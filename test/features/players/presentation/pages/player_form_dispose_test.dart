import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/players/presentation/pages/create_player_page.dart';
import 'package:dart_lodge/features/players/presentation/pages/edit_player_page.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the Sentry crashes MY-DARTS-9 / MY-DARTS-G:
///
///   StateError: Using "ref" when a widget is about to or has been
///   unmounted is unsafe.
///
/// The create/edit player pages used to call `ref.invalidate(...)` inside
/// `State.dispose()`, which reaches through the (already-disposing)
/// `ConsumerStatefulElement` and throws while the widget tree is being
/// finalized. Both providers are autoDispose, so tearing down the page
/// resets their state on its own — no manual invalidate is needed.
///
/// Each test mounts the page, then replaces the tree to force an unmount,
/// and asserts nothing was thrown during disposal.
Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('CreatePlayerPage disposes without touching ref (MY-DARTS-9)',
      (tester) async {
    await tester.pumpWidget(_app(const CreatePlayerPage()));
    await tester.pumpAndSettle();

    // Replace the whole tree so the page's element unmounts.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('EditPlayerPage disposes without touching ref (MY-DARTS-G)',
      (tester) async {
    await tester.pumpWidget(
      _app(const EditPlayerPage(playerId: 'p1', currentName: 'Alice')),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
