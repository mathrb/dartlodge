import 'package:dart_lodge/features/auto_scorer/domain/sharing/export_destination.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_pre_send_view.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a host whose button pushes the screen, recording what it pops.
Future<void> open(
  WidgetTester tester,
  void Function(PreSendChoice?) sink, {
  int photos = 12,
  int sessions = 2,
  String size = '34.5 MB',
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              sink(await Navigator.of(context).push<PreSendChoice>(
                  MaterialPageRoute(
                      builder: (_) => AutoScorerPreSendView(
                            photoCount: photos,
                            sessionCount: sessions,
                            sizeLabel: size,
                          ))));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('states what is inside, what it shows, and where it goes',
      (tester) async {
    await open(tester, (_) {});

    expect(find.text('12 training photos'), findsOneWidget);
    expect(find.text('2 recorded sessions'), findsOneWidget);
    expect(find.text('34.5 MB in total'), findsOneWidget);
    // The privacy reminder is the point of the screen.
    expect(find.textContaining('your room'), findsOneWidget);
    // The destination, and why it cannot simply be e-mailed.
    expect(find.textContaining(kAutoScorerExportContact), findsOneWidget);
    expect(find.textContaining('too big to send as an e-mail attachment'),
        findsOneWidget);
  });

  testWidgets('reads correctly with a single photo and no sessions',
      (tester) async {
    await open(tester, (_) {}, photos: 1, sessions: 0);

    expect(find.text('1 training photo'), findsOneWidget);
    expect(find.text('No recorded sessions'), findsOneWidget);
  });

  testWidgets('copies the address to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await open(tester, (_) {});
    await tester.tap(find.text('Copy the address'));
    await tester.pumpAndSettle();

    expect(copied, kAutoScorerExportContact);
    expect(find.text('Address copied'), findsOneWidget);
  });

  testWidgets('sharing pops send:true', (tester) async {
    PreSendChoice? choice;
    await open(tester, (c) => choice = c);

    await tester.tap(find.text('Open the share sheet'));
    await tester.pumpAndSettle();
    expect(choice?.send, isTrue);
    expect(choice?.dontShowAgain, isFalse);
  });

  testWidgets('"Not now" pops send:false so nothing is shared',
      (tester) async {
    PreSendChoice? choice;
    await open(tester, (c) => choice = c);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(choice?.send, isFalse);
  });

  testWidgets('a repeat sender can ask not to see it again', (tester) async {
    PreSendChoice? choice;
    await open(tester, (c) => choice = c);

    await tester.tap(find.text("Don't show this again"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open the share sheet'));
    await tester.pumpAndSettle();
    expect(choice, (send: true, dontShowAgain: true));
  });
}
