// Schema migration tests (#522) — the project's first drift migration.
//
// Uses drift's official SchemaVerifier against the committed schema snapshots in
// `drift_schemas/` (regenerate with `dart run drift_dev schema dump ...` +
// `dart run drift_dev schema generate drift_schemas/ test/drift_schemas/`).

import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../drift_schemas/schema.dart';
import '../../../drift_schemas/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 → v2 adds unlocked_achievements and preserves existing data',
      () async {
    final schema = await verifier.schemaAt(1);

    // Seed a player using the v1 schema (before unlocked_achievements existed).
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.customStatement(
      'INSERT INTO players (player_id, name, created_at, last_active) '
      "VALUES ('p1', 'Alice', '2026-01-01T00:00:00.000', "
      "'2026-01-01T00:00:00.000')",
    );
    await oldDb.close();

    // Run the real migration and validate the resulting schema matches v2.
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    // Existing data survived the upgrade...
    final players = await db.select(db.players).get();
    expect(players, hasLength(1));
    expect(players.single.playerId, 'p1');

    // ...and the new table is present + usable (FK to the surviving player).
    await db.into(db.unlockedAchievements).insert(
          UnlockedAchievementsCompanion.insert(
            playerId: 'p1',
            achievementId: 'first_180',
            unlockedAt: DateTime.now().toIso8601String(),
          ),
        );
    final unlocked = await db.select(db.unlockedAchievements).get();
    expect(unlocked, hasLength(1));
    expect(unlocked.single.achievementId, 'first_180');

    await db.close();
  });
}
