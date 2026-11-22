import 'package:dart_lodge/core/feedback/contact_email.dart';
import 'package:dart_lodge/core/feedback/contact_us.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('contactMailtoUri', () {
    test('targets the project address with a versioned subject', () {
      final uri = contactMailtoUri(version: '1.2.3');
      expect(uri.scheme, 'mailto');
      expect(uri.path, kDartLodgeContactEmail);
      expect(uri.toString(),
          'mailto:dartlodge@gmail.com?subject=DartLodge%20feedback%20(v1.2.3)');
    });

    test('omits the version when it is unknown', () {
      expect(contactMailtoUri().toString(),
          'mailto:dartlodge@gmail.com?subject=DartLodge%20feedback');
    });
  });

  group('openContactEmail', () {
    String? clipboard;

    setUp(() {
      clipboard = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<void> tapWith(WidgetTester tester, UriLauncher launcher) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  openContactEmail(context, version: '1.0.0', launcher: launcher),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens the mail app and copies nothing on success',
        (tester) async {
      Uri? launched;
      await tapWith(tester, (uri) async {
        launched = uri;
        return true;
      });
      expect(launched, contactMailtoUri(version: '1.0.0'));
      expect(clipboard, isNull);
      expect(find.text('No e-mail app found. Address copied.'), findsNothing);
    });

    testWidgets('falls back to copying the address when no mail app opens',
        (tester) async {
      await tapWith(tester, (_) async => false);
      expect(clipboard, kDartLodgeContactEmail);
      expect(find.text('No e-mail app found. Address copied.'), findsOneWidget);
    });

    testWidgets('falls back to copying the address when launching throws',
        (tester) async {
      await tapWith(tester, (_) async => throw PlatformException(code: 'x'));
      expect(clipboard, kDartLodgeContactEmail);
      expect(find.text('No e-mail app found. Address copied.'), findsOneWidget);
    });
  });
}
