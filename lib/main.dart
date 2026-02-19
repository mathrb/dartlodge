// Main entry point for the Darts App
// This file initializes the application and sets up the provider scope

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: DartsApp(),
    ),
  );
}