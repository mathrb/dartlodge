// Native Database Factory
// Opens a persisted drift database on Android/iOS/desktop using a file in
// the application documents directory. See issue #112 for the migration plan
// off sqflite.
//
// `NativeDatabase.createInBackground` runs the database on a background
// isolate so that schema work (and future heavy queries) don't block the UI.
//
// Note: this factory is invoked by `DriftHelper`, which is currently only
// reached on web (`kIsWeb` branch in `database_provider.dart`). Wiring this
// path on mobile is the next step in the consolidation — landing the factory
// here keeps the diff small when that flip happens.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:dart_lodge/core/utils/constants.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, DatabaseConstants.databaseName));
  return NativeDatabase.createInBackground(file);
}
