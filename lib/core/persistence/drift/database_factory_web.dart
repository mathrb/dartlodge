// Web Database Factory
// Platform-specific implementation for web platforms using SQLite WASM.
//
// Uses WasmDatabase (factory constructor) rather than WasmDatabase.open():
// open() starts a dedicated web worker and waits for its handshake, which
// hangs permanently in Firefox and Edge during development. The factory
// constructor loads SQLite WASM directly on the main thread — no worker,
// no handshake, same SQL semantics.
//
// Persistence is provided by IndexedDbFileSystem so data survives reloads.

import 'package:drift/wasm.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/wasm.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));

  final fs = await IndexedDbFileSystem.open(dbName: 'darts_db');

  // Register the VFS with the sqlite3 module so it can open files stored in
  // IndexedDB. Without this, sqlite3.open('/darts.db') fails with
  // "no such vfs". The fileSystem: parameter on WasmDatabase only handles
  // flushing writes back to IndexedDB after each statement.
  sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

  return WasmDatabase(
    sqlite3: sqlite3,
    path: '/darts.db',
    fileSystem: fs,
  );
}
