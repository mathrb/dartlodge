// Database Helper
// Singleton database access with SQLite for mobile platforms

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/constants.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static sqflite.Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DatabaseConstants.databaseName);
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);

    return await sqflite.openDatabase(
      fullPath,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future _createDB(sqflite.Database db, int version) async {
    await DatabaseMigrations.createVersion1(db);
  }

  Future _upgradeDB(sqflite.Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion; i < newVersion; i++) {
      final upgradeVersion = i + 1;
      if (upgradeVersion == 2) {
        await DatabaseMigrations.createVersion2(db);
      }
      // Add future version upgrades here
    }
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

Future<String> getDatabasesPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}