import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/app/app.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';

/// Regression for #616 (F-002): when the database fails to open at startup, the
/// app shows a styled, localized error surface (icon + message + Retry) instead
/// of a raw "Database failed to open: <exception>" string.
void main() {
  testWidgets('DB open failure renders the styled ErrorRetryWidget, not a raw string',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith(
            (ref) => Future.error(Exception('sqlite3.wasm 404')),
          ),
        ],
        child: const DartsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Styled surface: the shared widget, an error icon, and a Retry button.
    expect(find.byType(ErrorRetryWidget), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

    // Localized friendly message — and the raw exception is NOT exposed.
    expect(find.textContaining("couldn't open its data"), findsOneWidget);
    expect(find.textContaining('sqlite3.wasm 404'), findsNothing);
    expect(find.textContaining('Database failed to open'), findsNothing);
  });
}
