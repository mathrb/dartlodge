// Drift Database Helper
// Singleton database access using conditional imports for platform-specific backends

// Conditional import: Dart compiler selects ONE of these at compile time.
// The web compiler never sees database_factory_native.dart.
// The native compiler never sees database_factory_web.dart.
import 'database_factory_stub.dart'
    if (dart.library.ffi) 'database_factory_native.dart'
    if (dart.library.html) 'database_factory_web.dart';
import 'database.dart';

class DriftHelper {
  static AppDatabase? _database;
  static final DriftHelper instance = DriftHelper._init();

  DriftHelper._init();

  Future<AppDatabase> get database async {
    if (_database == null) {
      final executor = await createDatabaseExecutor();
      _database = AppDatabase(executor);
    }
    return _database!;
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.clearAllData();
  }
}