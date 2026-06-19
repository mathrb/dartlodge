# Audit de dérive documentaire — oracles du plan de vérification 1.0

> Date : 2026-06-19. Branche : `docs/1.0-verification-plan` (rebasée sur `main` @ `40ac44c`,
> heatmap epic #571 inclus). Méthode : 7 agents parallèles (doc vs code), rapport sans modification.
>
> **Note de méthode (important).** Le premier passage a tourné sur un `main` local en retard de
> 6 commits (toute la heatmap #579→#584). Les findings « heatmap absente » étaient des faux
> positifs ; après mise à jour de la branche, un audit ciblé heatmap a révélé les vraies dérives
> (docs non mises à jour par l'epic). **Leçon : toute vérification doit tourner sur `origin/main` à jour.**

---

## Tableau de synthèse

| Document | Verdict | P0 | P1 | P2 |
|---|---|---|---|---|
| `docs/games/x01.transitions.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/games/cricket.transitions.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/games/around-the-clock.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/games/count-up.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/games/checkout-practice.md` | ⚠️ dérive | 0 | 1 | 1 |
| `docs/statistics/x01.projections.md` | ⚠️ dérive | 0 | 1 | 1 |
| `docs/statistics/statistics.architecture.md` | ⚠️ dérive | 0 | 3 | 2 |
| `docs/statistics/projection-test-matrix.md` | ⚠️ dérive | 0 | 1 | 0 |
| `docs/DATABASE_DDL.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/DATA.md` | ✅ à jour | 0 | 0 | 0 |
| `docs/GAME-EVENT-SPECIFICATIONS.md` | ⚠️ dérive | 0 | 2 | 1 |
| `docs/UI_SCREEN_FLOWS_V3_FINAL.md` | ❌ forte dérive | 0 | 7 | 6 |
| `docs/design/DESIGN_SYSTEM.md` | ⚠️ dérive | 0 | 2 | 6 |
| `docs/REPOSITORY_INTERFACES.md` | ❌ forte dérive | 0 | 6 | 6 |
| `docs/STATE_MANAGEMENT.md` | ⚠️ dérive | 0 | 2 | 4 |
| `lib/l10n/arb/app_*.arb` (×7) | ✅ parité parfaite | 0 | 0 | 7 (cosmétique) |

**Aucun P0.** Les 6 docs « à jour » incluent l'essentiel des oracles de correctness (transitions de jeu) et de schéma (DDL/DATA). Les dérives les plus lourdes sont sur les **flux UI**, les **interfaces de repo** et le **state management** (oracles d'implémentation).

---

## Détail par document

### `docs/games/checkout-practice.md` — P1 + P2
- **P1** — Le doc décrit un drill « un seul checkout puis fin ». Le moteur
  (`stateless_checkout_practice_engine.dart:84-208`) + l'UI (`game_config_page.dart:337`,
  picker `setupSectionTargetSuccesses`) implémentent un **mode quota multi-succès** :
  `practiceSuccesses >= checkoutTargetSuccesses` (∞ si null → jusqu'à End Drill). Non documenté.
- **P2** — Sur multi-succès, `TurnStarted` réinitialise `score`/`turnStartScore` à 170 après un
  checkout (`:55-82`). Conséquence du point ci-dessus.

### `docs/statistics/statistics.architecture.md` — 3×P1 + 2×P2
- **P1** — §5.2/§6/§9.1 disent « ordre = `global_sequence` ». Le code trie par
  `(gameId, localSequence)` (`projection_runner.dart:22-27`) ; `global_sequence` est inutilisé.
- **P1** — Projections de succès **NineDarter** (`x01.nineDarter`) et **Games501** (`x01.games501`)
  câblées dans `achievementMetricsFromEvents` (`player_stats_assembler.dart:108-148`) — absentes du doc.
- **P1** — Chemin **heatmap** non documenté : `getDartPositions` lit `dart_throws` en **brut**
  (hors assembler/ProjectionRunner), filtré `is_complete=1` + x/y non-null
  (`statistics_repository_drift.dart:535-553`). Exception architecturale au principe « stats = projections ».
- **P2** — Structure de snapshot à deux niveaux (`{descriptor.id: {field: value}}`) non décrite.
- **P2** — Positions x/y persistées sur `dart_throws` non évoquées dans l'architecture stats.

### `docs/statistics/x01.projections.md` — P1 + P2
- **P1** — §10 table de reset dit « Turn stats → reset on **TurnEnded** ». Le code reset sur
  **TurnStarted** (`projection_runner.dart:30-33`) ; contredit par l'architecture, CLAUDE.md et la test-matrix.
- **P2** — Pas de note « first-nine / checkout-attempt / nine-darter / 501 exigent `TurnStarted` ».
- ✅ §5.2 (`turn_score` delta #318), checkout ≤170, ids de descripteur, snapshot keys : exacts.

### `docs/statistics/projection-test-matrix.md` — P1
- **P1** — §3 « golden rule : event order = `global_sequence`, nothing else » → doit être
  `(game_id, local_sequence)`. (§3-D1 reset `TurnStarted` est correct.)

### `docs/GAME-EVENT-SPECIFICATIONS.md` — 2×P1 + P2
- **P1** — §4.4 `DartCorrected` documenté avec `corrected_segment`/`corrected_multiplier`. Réalité
  (`undo_last_dart_use_case.dart:112-126`) : `original_event_id`, `corrected_dart_id`,
  `superseded_event_ids` (record d'undo/supersession, pas de re-score vision).
- **P1** — `TurnStarted` omet `player_id`/`leg_index`/`starting_score` ; `TurnEnded` omet
  `player_id` et le `turn_score` (#318) (`game_use_case_helpers.dart:62-91,141-168`).
- **P2** — `DartThrown` omet `player_id`, `score` (toujours présents) et le flag conditionnel `bust`.
- ✅ x/y (#571), `CrazyTargetsRolled`, `CricketTargetsAssigned`, `GameCreated`, `GameCompleted` : exacts.

### `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — 7×P1 + 6×P2 (forte dérive)
- **P1** — Routes board fausses : réel `/game/active/x01/:gameId`, `/game/active/cricket/:gameId`,
  `/practice-board/:gameId` (`app_router.dart:49-52,262-273`).
- **P1** — **Count Up board** absent (`/game/active/count-up/:gameId`).
- **P1** — **Achievements page** absente (`/achievements/:playerId`, depuis Player Stats).
- **P1** — **Auto-Scorer Settings** absent (`/settings/auto-scoring`).
- **P1** — Layout **Home** faux (doc = grille 2×2 + « coming soon » ; réel = liste de cartes
  kinétiques X01/Cricket/Casual/Practice + nav rows Statistics/History/Players).
- **P1** — **Settings** : réel = Theme 3-way + Language + Sound + Auto-Scoring + About + Feedback +
  Debug + Danger Zone (doc = Theme + About seulement).
- **P1** — **Heatmap** : deux surfaces absentes — `GameHeatmapSectionWidget` (post-game, sélecteur
  joueur) + `StatsHeatmapSectionWidget` (stats all-time par gameType, ignore le TimeRangeSelector).
- **P2** — param route variant `:category` (x01/cricket/casual/practice) ; Game Config = bottom
  sheet (pas de route) ; Edit Player absent ; `/stats` = player-picker (pas « deferred ») ;
  variantes camera-first des boards ; sémantique push/go + PopScope + onExit.

### `docs/design/DESIGN_SYSTEM.md` — 2×P1 + 6×P2
- **P1** — Light `primary` : doc `#AFFFD1`, code `#006D45` (`app_colors.dart:46`). Le doc affirme à
  tort que la famille `primary` est identique en clair/sombre ; seul `primaryFixed*` l'est.
- **P1** — Tokens **camera-first #477** non documentés : bande 110px,
  `scoreMedium`-dans-FittedBox-sur-labels, `HeroMetricWidget` (`scoreActive` + over-line
  `labelSmall`/`primaryFixed`), strips at-distance, `CricketMarkPainter`.
- **P2** — Hex obsolètes : dark `outlineVariant` `#46484A`→`#484848` ; §7.4 `surfaceBright`
  `#292C30`→`#2B2C2C` ; §10.1 `primaryFixedDim` `#00E297`→`#00F2A2`.
- **P2** — Noms de tokens : doc `textScore*`/`textSegmentButton`/`textMultiplierLabel` → code
  `score*`/`segmentButton`/`multiplierLabel` (sans préfixe `text`).
- **P2** — Colormap heatmap / KDE / couleurs board non documentés (cf. won't-fix #195 pour les
  couleurs dartboard domaine).
- **P2** — Dark `surfaceVariant` `#252626` / `onSecondary` `#003417` absents des tables ; notation
  letter-spacing `display-lg` (em vs px) — équivalent, cosmétique.

### `docs/REPOSITORY_INTERFACES.md` — 6×P1 + 6×P2 (forte dérive)
- **P1** — `getLeaderboard` fantôme (n'existe pas). 4 méthodes Statistics manquantes
  (`achievementMetricsForPlayer`, `getPlayerLegHistory`, `getPlayerX01StartingScores`,
  `getPlayerCricketVariants`) + params `getPlayerStats` manquants (`startingScore`, `variant`,
  `legLimit`, `cricketTargetMode`).
- **P1** — GameRepository : `saveGameState` fantôme ; `appendEventsAndCompleteGame` manquant ;
  `getCompletedGames` params `dateFrom`/`dateTo` manquants ; claim « completeGame clears
  game_state_json » obsolète.
- **P1** — `getLatestSequence` : doc « -1 si vide », code « 0 » (`game_event_repository.dart:22-24`).
- **P1** — `MultipleActiveGamesException` fantôme ; 6 exceptions réelles non documentées
  (`DuplicatePlayerNameException`, `StatisticsException`, `InvalidGameStateException`,
  `NoDartsToUndoException`, `DartNotCorrectableException`, `DatabaseException`).
- **P1** — §8 wiring obsolète : doc `appDatabase`/`*Impl`/typed `XxxRef` → réel `databaseProvider`/
  `*Drift`/plain `Ref` (Riverpod 3.x).
- **P2** — `deletePlayer`, `watchUnlockedDetails` manquants ; **entité `DartPosition` non définie**
  (référencée par `getDartPositions` mais sans bloc de champs) ; `GameStats.gameType` manquant ;
  stubs exceptions §4 vs §7 incohérents ; framing dual-backend sqflite obsolète (single drift).
- ✅ « toutes exceptions extends RepositoryException » et « getPlayerStats/watchPlayerStats prennent
  `required GameType` » : exacts.

### `docs/STATE_MANAGEMENT.md` — 2×P1 + 4×P2
- **P1** — Règle de suffixe `Notifier` (la « plus facile à violer ») absente ; exemples nommés
  `class ActiveGame` au lieu de `ActiveGameNotifier` → `activeGameProvider`.
- **P1** — Signatures à ref typée obsolètes (`GameRepositoryRef`…) → plain `Ref ref` partout (3.x).
- **P2** — Classes freezed sans `abstract` (3.x exige `abstract class … with _$…`) ;
  `watchGameEvents` inexistant (réel `GameEventRepository.watchEventsForGame`) ;
  `StateNotifierProvider`/`StateProvider` inutilisés dans le code ; note `AsyncValue.value` vs
  `valueOrNull` absente.

### `lib/l10n/arb/app_*.arb` (×7) — parité parfaite, P2 cosmétique
- Parité exacte : 515 clés par locale, 0 manquante, 0 orpheline, placeholders intacts (44 clés paramétrées).
- « Identiques à l'EN » majoritairement légitimes (nombres, jargon darts, noms propres de succès).
- Vrais (cosmétiques) : poignée de chaînes laissées en anglais par locale (loanwords surtout).
- **Lacunes côté CODE (pas ARB)** : surface debug `auto_scorer/` (33 littéraux EN, debug-only) et
  `count_up_board_page.dart` (3 chaînes user-facing EN — vraie lacune si Count Up est shippé).

---

## Recommandation de regroupement des corrections

Les corrections se regroupent naturellement par domaine (un PR `docs:` par groupe) :

1. **Stats** — `statistics.architecture.md` + `x01.projections.md` + `projection-test-matrix.md`
   (global_sequence, achievements, heatmap path, turn-reset).
2. **Events** — `GAME-EVENT-SPECIFICATIONS.md` (DartCorrected, Turn*/keys).
3. **Flux UI** — `UI_SCREEN_FLOWS_V3_FINAL.md` (réécriture lourde : routes, écrans manquants, Home, Settings, heatmap).
4. **Design** — `DESIGN_SYSTEM.md` (hex, noms tokens, camera-first, heatmap).
5. **Oracles d'implémentation** — `REPOSITORY_INTERFACES.md` + `STATE_MANAGEMENT.md`.
6. **Jeux** — `checkout-practice.md` (mode quota).
7. **i18n (code, pas doc)** — `count_up_board_page.dart` à localiser (la surface auto_scorer debug = won't-fix probable).

Priorité pour débloquer le plan de vérification : les oracles que le plan cite (stats, design,
UI-flows, transitions) avant les oracles d'implémentation (repo/state — utiles mais moins critiques
pour la phase de test).
