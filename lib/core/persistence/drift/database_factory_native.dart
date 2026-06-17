// Native Database Factory
// Opens a persisted drift database on Android/iOS/desktop using a file in
// the application documents directory.
//
// `NativeDatabase.createInBackground` runs the database on a background
// isolate so that schema work (and future heavy queries) don't block the UI.
//
// SQLite library: `sqlite3` v3 bundles its own up-to-date native library via
// Dart build hooks (native assets) on every platform — Android included — so
// there is no `sqlite3_flutter_libs` dependency and no
// `applyWorkaroundToOpenSqlite3OnOldAndroidVersions` / `DynamicLibrary.open`
// shim anymore (#126). The bundled library is registered process-wide, so the
// spawned `createInBackground` isolate resolves it without an `isolateSetup`.

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
