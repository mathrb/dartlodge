# Heatmap des impacts — Design

**Date :** 2026-06-19
**Statut :** validé (brainstorming), epic à créer

## Résumé

Avec l'auto-assist (auto-scoring caméra), on connaît la position précise de chaque
fléchette sur la cible. On veut représenter cette information sous forme de **heatmap
de densité** sur une cible factice, à deux endroits :

1. **Fin de partie** (X01, Cricket, …) — par joueur, avec sélecteur.
2. **Section statistiques** — agrégée par joueur, filtrable par type de jeu et par période.

La position `(x,y)` n'est **pas captur��e/persistée aujourd'hui** (le détecteur la calcule
mais elle est jetée après classification du segment). Le travail se découpe donc en deux
phases : **Phase 1 = pipeline de capture**, **Phase 2 = visualisation**. La heatmap ne
montre que les parties jouées en auto-assist *après* la Phase 1 (pas de backfill).

## Décision fondatrice : convention de coordonnées

À l'émission, l'auto-scorer normalise la position canonique de la fléchette dans un
repère **stable, indépendant du modèle et de la calibration** :

- origine `(0,0)` = centre de la cible ;
- rayon `1.0` = bord extérieur de l'anneau **double** ;
- orientation « 20 en haut », alignée sur `kDartboardClockOrder` ;
- un raté hors double a un rayon `> 1.0` (conservé — patterns de ratés utiles).

### Pourquoi le « 20 en haut » fonctionne même si la cible est tournée

Le repère canonique n'est pas ancré sur l'orientation de la caméra/du téléphone mais sur
les **4 points de calibration** (repères anatomiques de la cible, détectés par le modèle
comme 4 classes distinctes). Cf. `canonicalTransform()` dans
`lib/features/auto_scorer/domain/scoring/homography.dart` :

```
cal1 = fil 5/20  → HAUT     (cx, cy - r)
cal2 = fil 3/17  → BAS      (cx, cy + r)
cal3 = fil 8/11  → GAUCHE   (cx - r, cy)
cal4 = fil 13/6  → DROITE   (cx + r, cy)
```

L'homographie redresse la cible (même tournée, même vue en biais) pour que cal1 atterrisse
toujours en haut. C'est **la même transformation qui fait déjà fonctionner le scoring des
segments** : si une `T20` est correctement scorée avec la cible montée de travers, le point
de heatmap atterrit forcément au bon endroit. La heatmap **hérite gratuitement** de la
justesse d'orientation du scorer.

Seul cas de casse : le modèle confond l'identité des points de calibration (flip 180°). Mais
alors le scoring lui-même est faux — sujet de précision modèle/calibration existant (#393,
territoire du probe), pas un nouveau mode de défaillance introduit par la heatmap.

On ne réoriente rien nous-mêmes : on stocke la position canonique que le scorer calcule
déjà, normalisée par le rayon `radius` du `CanonicalTransform`.

**Orientation d'affichage (#697).** Le repère de scoring ancre le **fil 5/20 en haut**
(`cal1 → top`), donc le centre du segment 20 tombe à ~9° dans le sens horaire de la
verticale, pas dessus. `HeatmapDartboardWidget` applique une **rotation d'affichage**
(`kHeatmapDisplayRotation = -π/20`, soit −½ segment) à l'ensemble — wedges **et** image de
densité ensemble — pour montrer un tableau standard « 20 en haut » (fil 5/20 ~9° à gauche de
la verticale). Données stockées et homographie inchangées ; les impacts restent dans leur
wedge puisque les deux couches tournent ensemble.

## Phase 1 — Pipeline de capture

Faire transiter le `(x,y)` normalisé du tracker jusqu'à l'événement et la table.

1. **Normalisation à la source** (auto_scorer, domain). Le tracker a déjà
   `TrackedDart.boardPosition` (unités canoniques) + `centre`/`radius` via
   `CanonicalTransform`. La normalisation `(p - centre) / radius` aboutissant au repère
   « centre=0, double-ring=1 » s'écrirait :
   ```
   x = (boardPosition.x - centre.x) / radius
   y = (boardPosition.y - centre.y) / radius
   ```
   > **⚠️ Finding /plan (#572) :** `DartTracker._normalise` applique **déjà** cette
   > formule en construisant les candidats, donc `TrackedDart.boardPosition` est **déjà**
   > dans ce repère (vérifié par `scoreDartAt(..., 1.0)` où `rDouble = 1.0`). La
   > réappliquer à l'émission **double-normaliserait**. SI-1 ne fait donc qu'un
   > pass-through + un garde-fou bruit (`r > 1.5` → position null, segment conservé).
   > SI-2/SI-3 ne doivent **pas** re-normaliser.

   `SessionFrameResult.emittedDarts` porte désormais `(segment, x, y)` au lieu du seul
   `segment`.

2. **Le port `DartInputSink`** (core/domain) :
   `submitDart(String segment)` → `submitDart(String segment, {double? x, double? y})`.
   Doubles bruts (le port core ne doit pas dépendre du type `BoardPoint` de l'auto_scorer).
   Saisie manuelle → rien passé → `null`.

3. **Use cases d'émission** (`ProcessDartUseCase`, `ProcessCricketDartUseCase`, chemins
   practice) acceptent `x,y` optionnels et les propagent :
   - **`buildDartThrownEvent`** → nouvelles clés payload `x`, `y` (omises si null).
     Maj de `docs/GAME-EVENT-SPECIFICATIONS.md` + le test du key-set du payload.
   - **insertion `DartThrow`** → les champs `x`/`y` (déjà sur l'entité) sont enfin
     renseignés.

4. **Corrections.** `DartCorrected` (via `UndoLastDartUseCase`) réémet **sans** position
   → la fléchette corrigée a `x/y = null` (choix conservateur : une correction signale une
   détection douteuse). Vérifier que le replay/supersession ne réhérite pas l'ancienne
   position.

### Pas de migration de base

Les colonnes `dart_throws.x` / `.y` (`REAL nullable`) **existent depuis le schéma v1**
(`drift_schemas/drift_schema_v1.json`), mais n'ont jamais été remplies. Les peupler est une
**écriture de contenu**, pas un changement de structure → **aucun bump `databaseVersion`,
aucun `onUpgrade`, aucune régénération de snapshots**. Aucun backfill : parties passées et
fléchettes manuelles restent `NULL` et sont naturellement exclues.

## Phase 2 — Visualisation

### Widget heatmap

Nouveau widget partagé `lib/core/widgets/heatmap_dartboard_widget.dart`
(`HeatmapDartboardWidget`, `StatelessWidget`). Empilement à la `AtcAnnotatedDartboardWidget` :

```
Stack(
  DartboardHighlightWidget(noHighlight: true),   // cible factice réaliste réutilisée
  Positioned.fill(CustomPaint(painter: _HeatmapPainter(points, ...))),
)
```

Le painter consomme une `List<({double x, double y})>` de positions normalisées (position
continue exacte, **pas** des fréquences par segment comme l'ATC).

### Algorithme densité (KDE)

Dans `_HeatmapPainter` :
1. binning des points sur une grille (~64×64) couvrant `[-1.1, 1.1]²` ;
2. lissage gaussien (rayon de noyau paramétrable — petit pour fin-de-partie / peu de points,
   plus large pour gros volumes) ;
3. normalisation `0..1` puis mapping sur une colormap froide→chaude (transparent → bleu →
   cyan → jaune → rouge) avec alpha croissant ;
4. peint via `canvas.drawImage` d'une `ui.Image` générée depuis la grille (perf : pas N
   cercles), clippée au disque de la cible.

Perf : O(grille), pas O(points²) — des milliers de points en stats restent fluides. La
fonction KDE+colormap est **extraite en pur Dart** (testable hors canvas).

### Récupération des données

Les positions sont des **faits bruts par fléchette** (comme `segment`/`score`), pas une stat
calculée → on **ne passe pas** par `PlayerStatsAssembler`. Lecture directe de `dart_throws`
`WHERE x IS NOT NULL` (aussi le chemin le plus performant).

Nouvelle méthode sur le repository statistics (interface + impl drift) :
```dart
Future<List<DartPosition>> getDartPositions({
  String? gameId,                 // fin de partie : une partie
  required String playerId,
  GameType? gameType,             // stats : filtre par jeu
  DateTime? from, DateTime? to,   // stats : filtre période
});
// DartPosition = (double x, double y, String? segment)  — nouvelle petite entité domain
```
Provider famille `dartHeatmapProvider(filter)` → `AsyncValue<List<DartPosition>>`.

### Point d'intégration A — fin de partie

Dans `GameSummarySectionWidget` (core/widgets), après le tableau de stats : section « Carte
de chaleur » avec **sélecteur de joueur** (segmented control sur les compétiteurs), chacun
rendant `HeatmapDartboardWidget` sur `(gameId, playerId)`. Section masquée si la partie n'a
aucune position (jouée en manuel) ; compteur « N fléchettes manuelles non localisées » si
mixte.

### Point d'intégration B — statistiques

`PlayerStatsPage` est **déjà par joueur** et **déjà découpée en onglets** X01 / Cricket /
Practice / Others (= filtre « type de jeu » gratuit) et possède déjà `TimeRangeSelector`
(= filtre « période »). On ajoute une section heatmap dans les onglets pertinents, alimentée
par `dartHeatmapProvider(playerId, gameType: <onglet>, from/to: <TimeRange>)`. « Global » =
TimeRange « tout » + agrégat.

## Cas limites

- **Ratés hors double** (`r > 1.0`) : conservés/affichés, grille étendue `[-1.1, 1.1]²`.
  Garde-fou : `r > 1.5` = bruit → écarté.
- **Bull** (SB/DB) : positions proches du centre, aucun traitement spécial.
- **Partie mixte** : seules les fléchettes localisées comptent ; compteur « N non localisées ».
- **Comparabilité inter-modèles** : positions normalisées dans le repère canonique ancré
  calibration → comparables entre versions de modèle (héritent de la justesse du scorer).

## Tests

- **Phase 1** : math de normalisation (unitaire) ; les use cases injectent `x/y` dans le
  payload **et** dans `DartThrow` ; maj du test de key-set du payload ; correction → `null` ;
  chemin manuel → `null` ; `getDartPositions` filtre (game/player/type/période) et **exclut
  les NULL** (contrat).
- **Phase 2** : fonction KDE+colormap pure (binning/gaussien/mapping) hors canvas ; widget
  tests pour état vide masqué + bascule de joueur. Le rendu réel sur device n'est pas
  widget-testable (caméra/device).

## Non-objectifs (YAGNI)

- Pas de backfill des parties passées.
- Pas de heatmap par-segment (on a la position continue).
- Pas de heatmap live pendant la partie (post-game + stats seulement).
- Pas d'export image.
- Pas de comparaison côte-à-côte de deux joueurs.
- Filtre période = réutilisation de `TimeRangeSelector` (pas de date-picker custom).

## Découpage en sous-issues

| #     | Phase | Contenu |
|-------|-------|---------|
| SI-1  | 1     | Normalisation à l'émission + `SessionFrameResult` porte `(segment,x,y)` (auto_scorer) |
| SI-2  | 1     | `DartInputSink.submitDart({x,y})` + impls sink des boards forwardent |
| SI-3  | 1     | Use cases → payload `x/y` + `buildDartThrownEvent` + insertion `DartThrow` + spec doc + correction null |
| SI-4  | 2     | `HeatmapDartboardWidget` + fonction KDE pure + tests (core/widgets) |
| SI-5  | 2     | `getDartPositions` + entité `DartPosition` + `dartHeatmapProvider` + contrats (data) |
| SI-6  | 2     | Intégration fin de partie (sélecteur joueur dans `GameSummarySectionWidget`) |
| SI-7  | 2     | Intégration stats (sections dans onglets `PlayerStatsPage`, câblées aux filtres) |

Phase 1 (SI-1→3) débloque la donnée ; Phase 2 (SI-4→7) la visualise. SI-4 et SI-5 sont
parallélisables.

## Fichiers de référence

- `lib/features/auto_scorer/domain/scoring/homography.dart` — `canonicalTransform()`, `centre`/`radius`
- `lib/features/auto_scorer/domain/tracking/tracked_dart.dart` — `TrackedDart.boardPosition`
- `lib/core/providers/board_overlay_provider.dart` — seam cross-feature (pattern)
- `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart` — `DartboardHighlightWidget` + `kDartboardClockOrder`
- `lib/features/statistics/presentation/widgets/atc_annotated_dartboard_widget.dart` — pattern overlay sur cible
- `lib/core/widgets/game_summary_section_widget.dart` — intégration fin de partie
- `lib/features/statistics/presentation/pages/player_stats_page.dart` — intégration stats
- `lib/features/game/domain/usecases/game_use_case_helpers.dart` — `buildDartThrownEvent`
- `lib/core/persistence/drift/database.dart` — table `DartThrows` (colonnes `x`/`y` déjà présentes)
- `docs/GAME-EVENT-SPECIFICATIONS.md` — payload `DartThrown` (à mettre à jour)
