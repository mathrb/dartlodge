// Main entry point for the Darts App
// This file initializes the application and sets up the provider scope.
//
// Crash-reporting handlers (FlutterError.onError + PlatformDispatcher.instance.
// onError) are auto-installed by SentryFlutter.init via FlutterErrorIntegration
// and OnErrorIntegration respectively (sentry_flutter >= ~7.x; current pin is
// 9.19.0). Do NOT add manual handlers here — they would override Sentry's and
// silence the crash pipeline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app/app.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment(
        'SENTRY_ENVIRONMENT',
        defaultValue: 'development',
      );
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: DartsApp(),
      ),
    ),
  );
}