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
  // Same width as the default test window, three times the height: the screen
  // is a scrolling ListView, and with the sessions section (#763) the default
  // 800x600 cuts off the lower half — a tap or a `findsOneWidget` down there
  // would then depend on scroll position rather than on the screen's content.
  // Only the height is changed: at a narrower width the test font (fixed-width
  // glyph boxes, far wider than the real one) reports overflows the device
  // does not have.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
    // Nothing to describe, so the section that describes it stays away (#763).
    expect(find.text('What a recorded session holds'), findsNothing);
  });

  testWidgets('says what a recorded session holds, and what it does not',
      (tester) async {
    // Counted but never explained until #763, while the photos beside them
    // were. The reassuring half is that a session carries no images at all.
    await open(tester, (_) {});

    expect(find.text('What a recorded session holds'), findsOneWidget);
    expect(find.textContaining('no images'), findsOneWidget);
    // Named honestly: the bundle carries the game's competitor names, and its
    // timestamps say when it was played.
    expect(find.textContaining('player names'), findsOneWidget);
    expect(find.textContaining('when it was played'), findsOneWidget);
  });

  testWidgets('the loop after sending is not described as automatic',
      (tester) async {
    // #763: the old copy read as a hands-off pipeline with a short implied
    // delay, and promised a model that comes back "on its own" — true only on
    // Android, where the OTA channel exists.
    await open(tester, (_) {});

    expect(find.textContaining('hands-on work'), findsOneWidget);
    expect(find.textContaining('on no set schedule'), findsOneWidget);
    expect(find.textContaining('on its own'), findsNothing);
    // What has not changed: no on-device learning.
    expect(find.textContaining('Nothing is learned on your phone'),
        findsOneWidget);
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
