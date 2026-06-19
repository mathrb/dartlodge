# Axe 4 — Données / persistance — plan de test détaillé

> **Statut : passe 1 (chartes exploratoires par sujet).** Cas scriptés = passe 2 (différée).
> Parent : `docs/plans/2026-06-19-1.0-verification-plan.md` §6. Mécanique d'exécution + template :
> voir `axis-1-correctness.md` §2–§3. Principe directeur : **calculer la valeur attendue à la main
> depuis les événements, comparer à l'UI** (les stats sont des projections, jamais stockées).

---

## 1. Objet & oracles

Vérifier que ce qui est calculé et stocké est **exact et durable**. Stats = projections rejouées
depuis `game_events` ; history/succès/heatmap reflètent fidèlement les parties.

- Oracles : `docs/statistics/{x01.projections,statistics.architecture,projection-test-matrix}.md`
  (réalignés #585), `docs/DATABASE_DDL.md`, `docs/DATA.md`, `docs/GAME-EVENT-SPECIFICATIONS.md`,
  `docs/REPOSITORY_INTERFACES.md` (#586) + `PlayerStatsAssembler` / `ProjectionRunner`.
- Rail : quasi tout `[web]` (drift/IndexedDB ≈ natif) ; `[device]` pour le runtime sqlite3 minSdk23.

---

## 2. Sujets

### 2.1 Statistiques = projections
**Charte exploratoire** — *Missions*
1. **Moyenne 3-fléchettes X01 via delta `turn_score` (#318).** Partie avec visite bust et/ou Double-In non franchi : calculer `avg = (Σ turn_score / darts) × 3` (x01.projections §5.2) ; la visite bust contribue **0** au numérateur mais +1 par dart au dénominateur ; event legacy sans `turn_score` retombe sur la somme par-dart.
2. **Checkout % — définition de la tentative.** Tentative = `TurnStarted.starting_score ≤ 170` ET « in » (§6.4). Sonder 170 (compte) / 171 (non) ; **requiert `TurnStarted`** (sinon 0 → null).
3. **Highest checkout & buckets 100/140/180.** Buckets mutuellement exclusifs (180 exact n'apparaît pas aussi en 140+/100+) ; visites bust exclues.
4. **Cricket MPR/MPT + overload exact-N vs ≥-N.** Visite de 7 marques : per-game/leg → exact-7 (clés `*Exact`) ; carrière (`getPlayerStats`) → ≥5/≥6/≥7 (clés `*MarkTurns`). Identifier le chemin d'appel avant de juger.
5. **First-nine (X01 PPR / cricket MPR).** Requiert `TurnStarted` + garde ≥3 tours (leg court exclu du dénominateur, #290) ; `null` rendu proprement (pas « 0.0 »).
6. **Snapshot 2 niveaux & scope.** `snapshot[descriptor.id][field]` (architecture §5.3) ; carrière `fromEvents` / par-partie `gameStatsFromEvents` / par-leg `legCompetitorStatsFromEvents` cohérents.

**Heuristiques** — toute valeur affichée reproductible par rejeu à la main (sinon = stockée = défaut ; seule exception : heatmap §2.5) ; le dénominateur ment plus que le numérateur (recompter séparément) ; `null` ≠ `0.0` à l'écran ; corrections = rejeu complet ; strategy en littéraux minuscules `'straight'/'double'/'master'`.

### 2.2 Scope des resets & ordre d'événements
**Charte exploratoire** — *Missions*
1. **Frontières de reset exactes.** Turn sur `TurnStarted` (PAS TurnEnded), Leg sur `LegCompleted`, Match sur `GameCompleted` ; aucun autre. Runner : reset Turn **avant** `apply`, Leg/Match **après** — un reset au mauvais bord corrompt le snapshot du dart de frontière.
2. **Pas de fuite turn→turn.** Tour N (180) puis tour vide : snapshot N+1 sans résidu ; event non-`DartThrown` entre tours ne reset pas le Turn prématurément.
3. **Tri `(game_id, local_sequence)` multi-parties.** `local_sequence` redémarre à 1/partie → plages qui se chevauchent ; vérifier que `getPlayerStats`/`achievementMetricsForPlayer`/`getPlayerLegHistory` trient par les deux, et que `ProjectionRunner` réimpose le tri.
4. **Pas de pollution cross-game/leg.** Match multi-legs + multi-parties : compteurs Match ne débordent pas, Leg ne survit pas à `LegCompleted` (test-matrix XG1/XG2).
5. **`replayFrom` cutoff per-game.** Filtré par `localSequence >= fromSequencePerGame[gameId]` ; un cutoff global unique drop par erreur des events co-chargés.

**Heuristiques** — reset au mauvais bord = inclut/exclut le dart de frontière ; `orderBy(localSequence)` seul sur un chemin multi-parties = bug (mono-partie OK) ; idempotence : run complet ≡ `replayFrom(0)` ; events event-only (LegCompleted/bust-via-TurnEnded) déclenchent des resets sans dart — un fixture DartThrown-seul les rate.

### 2.3 Historique
**Charte exploratoire** — *Missions*
1. **Liste & ordre.** Seulement `is_complete=1` + `end_time` non nul, triées `end_time` DESC ; abandonnées/en cours jamais présentes.
2. **Pagination (`loadNextPage`/offset, `_pageSize=20`).** Tailles 20/21/40/41/grand N : aucun doublon, aucun trou, dernière page partielle non omise ; `hasMore` correct ; appels parallèles rapides gardés (`_loadingNextPage`).
3. **Filtres & survie à `invalidateSelf`.** Type + plage de dates (inclusives sur `end_time`), poussés en base ; `_filter*` survivent au rebuild ; filtre+pagination combinés ; `clearFilters`.
4. **Détail = leg-breakdown correct.** `legStats` (events triés `localSequence`) = gagnant/darts/stats par ligne (PPR/checkout/180s X01 ; MPR/first-9/marks Cricket).
5. **Cross-check à la main.** Reconstruire stats par leg depuis les events bruts pour 1 partie X01 + 1 Cricket, comparer au détail ET à `getGameStats` (cas piège : bust, Double-In non validé, buckets, overflow).
6. **Lecture seule & carte résumé.** Ouvrir le détail n'émet/altère aucun event ; gagnant trié en tête, score `a–b`, libellé variante **minuscule** en historique.

**Heuristiques** — tailles pile sur multiples de `_pageSize` ; set d'IDs cumulés == `getCompletedGames(∞)` ; oracle indépendant (recompter, pas faire confiance à `computeLegStats`) ; champs null → `'—'` ; zéro mutation en lecture.

### 2.4 Achievements (données/persistance)
**Charte exploratoire** — *Missions*
1. **Déblocage au bon moment (NineDarter).** Seulement sur 501 fini en 9 fléchettes authentiques (pas 10+, pas 301/701, pas busté/non terminé) ; `hasNineDarter` via `x01.nineDarter`.
2. **Seuils des compteurs (Games501, total180s, highestCheckout, totalWins).** `value >= threshold` exact : tester N-1 / N / N+1 ; `big_fish` (170 explicite) ; binaires sans seuil (1ʳᵉ occurrence).
3. **Persistance + idempotence.** Ligne dans `unlocked_achievements` (PK `player_id+achievement_id`) ; `recordUnlock` idempotent (conflit PK avalé, premier `unlocked_at`/`game_id` conservés) ; aucun 2ᵉ toast/doublon au replay/reload.
4. **Détection réactive & survie au reload.** Watcher (keepAlive) détecte sur partie *nouvellement* complétée, joueurs participants seulement ; `earned.difference(already)` ; no-backfill (snapshot initial `_processed`).
5. **Comportement FK à la suppression.** Supprimer la partie → `game_id` NULL (trophée conservé) ; supprimer le joueur → CASCADE ; FK inexistante → `DatabaseException` (PAS avalée comme le conflit PK).
6. **Faits persistés, pas des GameEvents.** Aucun `AchievementUnlocked` event ; pas de colonne progress/notification.

**Heuristiques** — frontières de seuil exactes ; faux positifs (mauvaise partie/joueur, avant complétion) ; distinguer « déjà débloqué » (no-op) de « échec d'écriture » (doit remonter) ; multi-joueurs (1 partie crédite plusieurs, chacun sur son historique cross-type) ; migration v1→v2 (`unlocked_achievements`) couverte par `migration_test`.

### 2.5 Heatmap (données/persistance)
**Charte exploratoire** — *Missions*
1. **Double persistance auto-scorée.** `submitDart(seg, x:, y:)` → payload `DartThrown` (clés plates `x`/`y`, ajoutées `if != null`) → colonnes `dart_throws.x/.y` ; même couple dans event ET ligne.
2. **Null-by-construction (manuel + corrigé).** Chemins non-auto passent `x:null,y:null` → clés omises → NULL ; jamais de fléchette manuelle avec x/y non-null.
3. **Contrat `getDartPositions` (bypass projection).** Lit `dart_throws` directement (jamais l'assembler), 3 prédicats : `playerId`, `x/y NOT NULL`, `games.is_complete=1` ; segment réel conservé (pas normalisé MISS).
4. **Correction qui retire une position.** Préserve l'invariant : pas de position « fantôme » d'une détection annulée.
5. **Agrégation `dartHeatmapProvider` / filtre temporel.** Post-game (`gameId`) vs all-time-par-`gameType` (`from/to=null`) ; la vue stats **ignore délibérément** le `TimeRangeSelector` (décision mainteneur) — non-application = décision UI, pas limite repo.

**Heuristiques** — cadre canonique (origine=centre, r=1.0 au double, 20 en haut ; pas de pixels/repère caméra) ; clés plates `x`/`y` ; omission ≠ sentinelle (0,0 = bull légitime, jamais NaN) ; asymétrie manuel/auto voulue ; x/y `REAL` nullable depuis v1 (pas de migration #571) ; faits pas projections.

### 2.6 Persistance & replay
**Charte exploratoire** — *Missions*
1. **Restauration exacte au reload.** Recharger en plein jeu reconstruit l'état exact par replay (score, joueur actif, round, darts du tour, cibles cricket, targets verrouillées, in/out, currentTarget) ; aucune entrée perdue/dupliquée ; points de reprise délicats (après TurnStarted sans dart, bust non acquitté, bascule de leg).
2. **Déterminisme vs RNG.** Replay identique même avec RNG (`CrazyTargetsRolled`, random) : valeur figée à l'émission, `apply()` pur, jamais re-roll.
3. **Ordre `(game_id, local_sequence)` multi-parties.** Plages qui se chevauchent (`UNIQUE (game_id, local_sequence)`) ; toute requête cross-parties trie par les deux, jamais `local_sequence` seul.
4. **Supersession `DartCorrected` replay-aware.** `original_event_id` collecté + originaux sautés par `PlayerStatsAssembler` ET `UndoLastDartUseCase` ; pièges : correction puis undo au passage de tour, corrections multiples, dernier dart d'un leg.
5. **Lecture seule des parties terminées (logique app, pas trigger).** `is_complete=1` → `appendEvent(s)` rejette dans la transaction (anti-TOCTOU, relit `gameRow.isComplete`) ; aucun chemin (undo/auto-advance/correction tardive) ne contourne.
6. **IndexedDB & intégrité FK.** Données survivent au vrai reload (WASM/IndexedDB) ; `CASCADE` (games→enfants), `RESTRICT` (joueur historisé non supprimable), `SET NULL` (`current_turn_player_id`, `unlocked_achievements.game_id`).

**Heuristiques** — tester le reload au début/milieu/fin de tour/leg/partie ; oracle = recompté à la main (pas l'état mémoire avant reload) ; compter darts rejoués vs `dart_throws` persistés ; idempotence (rejouer 2× = même état) ; verrou read-only sous course (append concurrent à `completeGame`) ; vrai reload navigateur (pas rebuild de provider) pour exercer IndexedDB.

---

## 3. Sortie

- Findings données → carnet `docs/testing/findings-2026-06.md` (format plan §8).
- Cas scriptés (passe 2) : parties à valeurs connues, 9-darter émulé, reload, heatmap à positions connues — _[à dériver après la 1re passe exploratoire]_.
