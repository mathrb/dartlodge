# Axe 1 — Correctness (scoring) — plan de test détaillé

> **Statut : SQUELETTE.** Charpente + template + oracles posés. Contenu détaillé rempli en 2 passes :
> (1) **charte exploratoire** par jeu, (2) **cas scriptés** dérivés de la 1re passe exploratoire.
> Parent : `docs/plans/2026-06-19-1.0-verification-plan.md` §3.

---

## 1. Objet & oracles

Vérifier que **le score affiché et l'état du jeu sont toujours justes**, de bout en bout
(saisie → event → projection → UI), en ciblant l'intégration et les cas-limites de fin (les
moteurs purs sont déjà couverts par les tests unitaires/contract).

**Oracles par jeu :**

| Jeu | Oracle |
|---|---|
| X01 | `docs/games/x01.transitions.md` + `docs/statistics/x01.projections.md` |
| Cricket (+ variantes) | `docs/games/cricket.transitions.md` |
| Around the Clock | `docs/games/around-the-clock.md` |
| Checkout Practice | `docs/games/checkout-practice.md` |
| Count Up | `docs/games/count-up.md` |
| **Shanghai** | `docs/games/shanghai.md` (oracle canonique créé 2026-06-19) |
| **Catch 40** | `docs/games/catch-40.md` (oracle canonique créé 2026-06-19) |
| **Bob's 27** | `docs/games/bobs-27.md` (oracle canonique créé 2026-06-19) |

> **Gap doc comblé (2026-06-19)** : Shanghai / Catch 40 / Bob's 27 n'avaient pas de table de
> transitions. Des oracles **canoniques** (sources externes, indépendantes de l'engine) ont été
> créés dans `docs/games/`. Chacun liste les **divergences engine↔canonique** à trancher (§7 de
> ces docs) — notamment **Bob's 27 : manche bull finale absente → max 1287 vs 1437 documenté**.

---

## 2. Mécanique d'exécution

Deux mécaniques d'entrée des fléchettes, à tester toutes les deux :

### Rail manuel (path utilisateur par défaut)
- On clique les **boutons segment réels** de la grille (libellés sémantiques type
  « Triple 20 20 », « Miss MISS »).
- Gotchas (cf. `reference_e2e_playwright_runner` / `feedback_playwright_flutter_web`) :
  cliquer d'abord le `<flt-semantics-placeholder>` pour exposer l'arbre widget ; pour les
  boutons animés, `el.click()` via `browser_evaluate` ; **viewport-only** (pas de `isMobile`,
  pas de DPR — sinon timeout).

### Rail sim (auto-scoring / camera-first)
- `--dart-define=AUTOSCORER_SIM=true` au lancement → expose `window.dartlodgeSim`.
- Hooks : `dartlodgeSim.enableAutoScoring()` (bascule en camera-first), `dartlodgeSim.emit('T20')`
  (injecte une fléchette détectée via `DartInputSink.submitDart`), `dartlodgeSim.advance()`
  (tour suivant — bypasse les gardes board-clear, contrôle direct).
- ⚠️ Le sim mocke **post-détection** : il n'exerce PAS le tracker natif / cap 3-fléchettes /
  board-clear (Android-only). La correctness du *scoring* à partir d'un segment détecté EST
  couverte ; la détection elle-même ne l'est pas (rail device).

### Assertions
- Lire scores / marks / cibles depuis le DOM-sémantique ; screenshots pour preuve visuelle.
- Format segment canonique (CLAUDE.md) : `'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`.

---

## 3. Template de cas de test

```
### C1-NN — <titre court>
- Jeu / config : <ex. X01 501, double-out, 2 joueurs>
- Rail input   : manuel | sim
- Préconditions: <état de départ>
- Séquence     : <suite de darts/actions, ex. T20, T20, T20 → advance>
- Attendu      : <état/score attendu> (oracle : <doc#section>)
- Type         : scripté (candidat e2e) | exploratoire
- Rail         : web | device
```

Charte exploratoire (par jeu) = **missions** (« explore X, note tout ce qui dévie de l'oracle »)
+ **heuristiques** (où regarder en priorité). Pas d'étapes figées.

---

## 4. Sections par jeu

> Chaque section : (a) **Charte exploratoire** [passe 1] — missions + heuristiques ;
> (b) **Cas scriptés critiques** [passe 2, après expl.] ; (c) **Cas-limites** ; (d) rappel oracle.

### 4.1 X01

**Charte exploratoire** — *Missions*

1. **Bust & restauration de score.** Provoquer chaque déclencheur de bust (`resulting_score < 0`, `== 1`, échec de validation Out) ; vérifier que le score revient exactement à `turn_start_score`, que le tour se termine de force (y compris bust au 1er/2e dart → darts restants perdus), que `turn_score` (#318) = 0 pour un tour busté, et que ce tour compte dans `bust_rate` ET `total_turns`. Oracle : x01.transitions.md §F (Table F), §4 ; x01.projections.md §5.2/§5.3.
2. **Out × In strategy (9 combinaisons).** Double/Master/Straight In × Out. Confirmer qu'un tour « pas encore in » ne change pas le score et contribue 0 au PPR (Table C, §5.2), qu'un dart raté en in consomme un dart sans finir le tour, que la fermeture exige le bon multiplicateur (Table E ; Bull=50 compté comme double). Noter tout `LegCompleted` émis sur un dart de fermeture invalide.
3. **Checkout, highest checkout & buckets.** Détection de tentative (score ≤ 170 ET « in » en début de tour, §6.4), `checkout_pct` (§6.5), `double_out_success_pct` (§8.2), `highest_checkout` (§7.3), buckets 100/140/180, `highest_turn_score` (§7.4). Sonder le seuil 170, l'égalité ≤ 1, les tours partiels.
4. **Round cap → leg décidée au classement.** `x01_total_rounds` fixé, atteindre le cap sans gagnant (Table M) : solo → winner `null` ; plus bas score net clair → auto-winner ; ex-aequo → `roundCapReached` + prompt (aucun `LegCompleted`/`GameCompleted` persisté avant `selectCapWinner`). Vérifier qu'un checkout naturel au dernier dart du round capé gagne quand même.
5. **Transitions leg/match multi-legs.** `legs_to_win > 1` : cycle `LegCompleted` → reset (Table K) → `GameCompleted` quand `legs_won == legs_to_win`. Aucun `DartThrown` après `GameCompleted`. Exclusion des parties solo des totaux career legs (§6.1, #106) alors que les stats par-partie comptent la leg.
6. **Parité des deux rails.** Rejouer une même séquence en manuel puis en sim ; events (`DartThrown`, `TurnEnded.turn_score`), buckets et average doivent être identiques.

**Heuristiques**
- Foyer historique : croisement score-restore ↔ turn-end (bust au 1er dart ; bust sur dart de fermeture invalide Double/Master Out) — Table E↔F.
- `turn_score` delta (#318) vs somme par-dart : tout chemin omettant `turn_score` retombe sur la convention legacy ; tours bust et « Double-In pas-encore-in » doivent contribuer 0.
- `TurnStarted` manquant → first-dart-in / checkout-attempts / nine-darter / 501 silencieusement null/0 (§10) — vérifier les deux rails.
- Seuils limites : `== 1` → bust (pas 0) ; 170 exact = en range ; 180/140/100 exacts ; Bull=50 = double pour in/out.
- Frontières de reset des projections : Turn sur `TurnStarted`, Leg sur `LegCompleted`, Match sur `GameCompleted` — un compteur qui ne se reset pas fuit d'un leg à l'autre.
- `DartCorrected` force le recalcul depuis le dart corrigé (§9) — sonder un checkout ou un bucket modifié par correction.

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/x01.transitions.md`, `docs/statistics/x01.projections.md`.

### 4.2 Cricket (+ scoring × target modes)

**Charte exploratoire** — *Missions*

1. **Modes de score × modes de cible (matrice orthogonale).** Parcourir les 9 combinaisons `scoring` {standard, cut-throat, no-score} × `target_mode` {fixed, random, crazy} (§1). Vérifier que l'ensemble des cibles vient de l'état (`cricket_targets` + Bull implicite) et non d'un `[15..20]` codé en dur, que `random` émet un seul `CricketTargetsAssigned` post-`GameCreated`, et que la victoire suit la bonne table G1/G2/G3.
2. **Fermeture, overflow et scoring.** `hits` capé à 3 (Table D) puis overflow `max(0, hits+mult-3)` (Table E, §5.1) sur les 3 modes. **Bull = 25 par overflow** y compris inner bull (§5.2). Cas adversaire-déjà-fermé (aucun point).
3. **Comptage « marks » par tour (régression #569).** Sur fixed/random/crazy, lancer sur des segments hors-cible : segment **affiché** (band/historique) mais marks du tour comptés **uniquement** sur cibles actives. Comparer manuel (boutons : cibles + MISS) vs sim (segment réel) — asymétrie intentionnelle ; noter toute fuite de marks sur segment inactif.
4. **Mode crazy : rotation, lock global, discard.** `CrazyTargetsRolled` après **chaque** `TurnStarted` (§2), nombres verrouillés conservés + non-verrouillés re-tirés distincts (Bull exclu), lock global sur fermeture, scope par-leg, discard-on-rotate (marks effacés sur un nombre qui quitte l'ensemble actif).
5. **Fin de leg : victoire naturelle, départage, round cap.** `all_closed` + évaluation après **chaque** dart (Tables F/G). Égalités → départage par **`close_order` le plus précoce** (immuable). Round cap (Table N) ne fire que sur `TurnEnded` du dernier compétiteur, jamais pendant un `DartThrown` ; métrique par variante.
6. **Bornes de turn.** Rejet des darts sur jeu complet / turn inactif / `darts == 3` (Table B) ; `TurnEnded` auto à 3 darts ; nombres 1–14/21–24 comptés lancés mais sans effet (§5.6).

**Heuristiques**
- Orthogonalité : changer une seule variable (scoring OU target_mode) et vérifier que l'autre axe est inchangé ; interférence croisée = suspecte.
- Oracle-diff : recalculer à la main `new_hits = min(hits+mult,3)` et `overflow = max(0, hits+mult-3)`, comparer à l'affichage (Table D/E).
- Bull obsessionnel : SB (25,×1) et DB (50,×2) en sous-clôture / clôture / overflow → toujours **25/overflow** (§5.2).
- Affiché ≠ compté : distinguer ce que l'UI montre (segment réel) de ce qui est crédité (marks/score) — surtout #569 et crazy.
- Timing : victoire/clôture après chaque dart ; round cap seulement sur `TurnEnded` (Tables G vs N, invariants opposés).
- Immutabilité `close_order` : un départage qui retombe sur l'ordre de rotation = bug.
- Reset de leg : à `LegCompleted` non finale → hits=0 / score=0 / all_closed=false / close_order=null ET `cricketLockedTargets` vidé.
- Replay déterministe : RNG (random/crazy) tourne une seule fois à l'émission, atterrit dans le payload — un replay ne re-tire jamais.

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/cricket.transitions.md`.

### 4.3 Around the Clock (+ variantes)

**Charte exploratoire** — *Missions*

1. **Progression nominale par variante.** Pour `standard` / `reverse` / `doublesOnly` : progresser de la cible de départ (1/20/1) jusqu'à la victoire en coups valides, vérifier le sens d'avancée, le bascule `completed` sur la dernière cible (20/1/20), `LegCompleted` émis sur la fléchette de complétion. Sur **les deux rails**.
2. **Rejets et non-avancées (cœur des bugs).** Ce qui ne doit PAS faire avancer : segment ≠ cible (hors-séquence, y compris cible future, §6), Bull/`SB`/`DB`/`MISS` (§5.3), et en `doublesOnly` un simple/triple sur la bonne cible (Table D2). Dans chaque cas : cible inchangée, fléchette quand même comptée (Table G), pas de `LegCompleted`.
3. **Fin de tour & victoire immédiate mi-tour.** Tour fini sur 3 fléchettes ; surtout la victoire sur la 1re/2e fléchette → les restantes NON lançables (Table F, invariant §4). Rejet d'un `DartThrown` après complétion / jeu terminé (Table B, L).
4. **Rotation multi-joueurs & continuation après complétion.** ≥2 joueurs : rotation correcte de `current_player` à chaque `TurnEnded` (Table I), continuation en rotation après qu'un joueur a complété, conclusion quand le vainqueur est déterminé (§5.7).
5. **Cohérence engine ↔ projection ↔ UI.** Sur une partie complète, confronter l'état rendu (cible, joueur actif, progression) au flux d'events et au moteur, surtout aux transitions de tour et à la complétion.

**Heuristiques**
- Variante = littéral lowercase `'standard'`/`'reverse'`/`'doublesOnly'` ; jamais comparer aux libellés UI (« Doubles Only »).
- `doublesOnly` exige `multiplier == 2` ; double sur la mauvaise cible n'avance pas non plus.
- Multiplicateur ignoré en standard/reverse : seul le numéro compte (§5.1).
- `SB`/`DB`/`MISS` = trous noirs : consomment une fléchette, n'avancent/complètent jamais.
- Hors-séquence = aucune avance mais fléchette comptée (Table G) — guetter une non-avance qui « avale » ou double-compte la fléchette.
- Bornes : `1 ≤ current_target ≤ 20` (§4) ; surveiller tout dépassement à la complétion.
- Victoire = sur la fléchette (Table F), tour clos sur-le-champ ; chercher la fléchette « fantôme » lançable après complétion.
- Reset de leg multi-leg : remet la cible de départ selon la variante + `completed=false` (Table K) sans contaminer le leg suivant.
- Parité des rails : manuel et sim doivent produire un flux d'events identique.

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/around-the-clock.md`.

### 4.4 Shanghai

**Charte exploratoire** — *Missions*

1. **Cible par round & calcul du score.** « cible = numéro du round » (round 1→1 … 7→7), scoring per-dart `roundNum × multiplier` créditant SEULEMENT le numéro courant ; bull `25` exclu, `MISS` = 0. Vérifier que `practiceRound` (et non l'index global) pilote la cible quand des joueurs sont à des rounds différents.
2. **Victoire instantanée « Shanghai ».** Condition exacte : single + double + triple du numéro du round dans les 3 mêmes fléchettes (`{'$r','D$r','T$r'}`), évaluée à la 3e fléchette. Ordre indifférent (set) ; solo (winner=null mais `isComplete` + `practiceSuccesses++`) vs multi (winner = lanceur) ; 4e dart impossible ensuite ; faux-positif = 3 touches sans couvrir les 3 multiplicateurs.
3. **Fin normale & gagnant.** Cap `shanghaiTotalRounds` (défaut 7) : fin quand TOUS ont `practiceRound > total` ; winner multi = plus haut score, **premier en cas d'égalité** ; solo = pas de winner ; aucun round au-delà du cap.
4. **Rotation & garde-fous.** Rotation `(index+1) % n` sur `TurnEnded` ; rejet `DartThrown` hors turn / >3 darts, `TurnStarted` si turn déjà actif ; tout event sur état complet rejeté sauf `GameCompleted`.
5. **Parité des deux rails.** Même séquence (round scoring, Shanghai, fin, égalité) en manuel puis sim → `score`/`practiceRound`/`practiceSuccesses`/`winnerCompetitorId`/`isComplete` identiques.

**Heuristiques**
- Frontière : cible exacte vs round±1 ; multiplicateurs sur la bonne cible vs une autre (0 pt).
- Set vs multiset : deux triples ne satisfont PAS le Shanghai ; ordre indifférent.
- Solo vs multi systématiquement (winner null vs lanceur/plus-haut-score).
- Timing : conditions de fin uniquement à la 3e fléchette.
- Cap : exactement round 7, juste avant/après ; aucun round fantôme.
- Bull et MISS non-scorants, ne déclenchent jamais de Shanghai.
- Replay : rejouer les events reproduit l'état (moteur pur).

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/shanghai.md` (canonique). **Tester engine vs canonique**, pas l'inverse.
- **Divergences canonique↔engine (voir shanghai.md §7)** : le **texte de règles** dit « solo » alors que le canonique ET l'engine sont multi-joueurs (→ corriger le texte, pas l'engine, D-1 P2) ; tie-break engine « premier » vs canonique « count triples » (D-2 P2, décision mainteneur) ; N de manches configurable (défaut 7, design légitime).

### 4.5 Catch 40

**Charte exploratoire** — *Missions*

1. **Séquence des cibles (61→100).** 1re cible = 61 (`60 + practiceRound`, initial 0), chaque `TurnEnded` qui avance → +1, 40e cible = 100 (ni 101 ni arrêt à 99). Fin : `newPracticeRound > 40` → exactement 40 cibles puis `isComplete`.
2. **Bust et reset de la cible.** Les 3 branches de bust : sous zéro, atterrissage sur 1, zéro par un non-double. `effectiveRemaining` retombe sur `currentTarget` tandis que `catch40DartsOnTarget` continue (le bust ne rend PAS la fléchette). Checkout exige un double.
3. **Allocation 6 fléchettes / 2 visites & barème.** Entre tour 1 et 2, `TurnEnded` n'avance PAS la cible tant que `dartsOnTarget < 6` et `remaining != 0`. Barème : ≤2 fléchettes → 3 pts ; 3 → 2 pts SAUF cible 99 → 3 pts ; 4–6 → 1 pt ; échec après 6 → 0. Plafond cumulé 120.
4. **Suivi attempts/successes & fin.** `practiceAttempts += 1` toujours, `practiceSuccesses += 1` seulement si `checkedOut`. `gameCompleted` émis seulement quand la 40e cible avance (garde-fou #253) ; `winnerCompetitorId` reste `null`.
5. **Deux rails + multi-joueur réel vs « solo » documenté.** Rejouer une cible en manuel puis sim, comparer l'état. Sonder le cas multi-competitors : l'engine route par `currentTurnIndex`/`competitor_id` alors que les règles disent « solo ».

**Heuristiques**
- Oracle de cible : cible affichée == `61 + nb cibles déjà avancées` ; remaining ≤ cible courante.
- Invariant de bust : ne change ni `practiceRound` ni `score`, n'arrête pas le décompte des 6 fléchettes.
- Double obligatoire : tout `remaining == 0` sans `multiplier == 2` = bust.
- Frontière de visite : `TurnEnded` au 3e dart sans checkout et `dartsOnTarget < 6` → même cible ; au 6e ou sur checkout → avance.
- Monotonie : `score`/`practiceAttempts`/`practiceRound` non-décroissants ; `successes ≤ attempts` ; `score ≤ 120`.
- Exception 99 : seul point du barème où 3 fléchettes = 3 pts.
- Parité des rails ; garde-fou de fin (40 cibles ⇒ `isComplete`, apparition en History).

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/catch-40.md` (canonique). **Engine = canonique, aucune divergence connue** (vérifié 2026-06-19 : 61→100, 6 fléchettes, barème 3/2/1, exception 99→3, max 120, solo).

### 4.6 Bob's 27

**Charte exploratoire** — *Missions* (⚠️ comportements à confronter aux règles canoniques en ligne — voir §8)

1. **Marche nominale des 20 manches.** Manche 1→20, cible attendue `D{round}` ; score de départ 27 ; delta appliqué seulement au 3e dart ; gain `+round×2×hitCount` (1/2/3 doubles), perte `−round×2` sur blanchissage complet. Run parfait = 1437.
2. **Frontière « busted » / score ≤ 0.** L'engine déclenche `isComplete` dès `newScore <= 0` (zéro pile termine aussi) sans flag de défaite (`winnerCompetitorId: null`). Construire des états passant juste à 0 vs juste sous 0.
3. **Fin de manche 20 & priorité des deux fins.** Après le 3e dart de la manche 20, fin (`roundNum >= 20`) quel que soit le score ; cohérence quand `score<=0` ET `round>=20` simultanés. **Pas de manche bull** au-delà de D20 (ni engine ni règles affichées).
4. **Standing / vainqueur mono- vs multi-joueurs.** Règles « solo » mais câblage multi-competitor (rotation `(index+1)%n`). Fin globale ou par-joueur ? Classement final et vainqueur quand `winnerCompetitorId` reste `null` — non spécifié.
5. **Parité des deux rails.** Même manche en manuel puis sim : évaluation au 3e dart, `hitCount` (segment canonique `D{round}`), deltas identiques. Un double **autre** que celui de la manche (ex. D5 en manche 3) = raté ; single/triple/bull/MISS ne modifient jamais le score.

**Heuristiques**
- Scoring différé : seul le 3e dart applique gain/perte ; un undo avant le 3e dart ne produit aucun delta.
- `hitCount` lit les 3 derniers darts (`sublist(len-3)`) — sonder undo/redo et tours interrompus qui désaligneraient la fenêtre.
- Seul `D{round}` strict compte ; near-misses (single même numéro, triple, double voisin, bull) = ratés.
- Perte fixe `−round×2` quel que soit le nombre de ratés.
- Fin sur `score<=0` inclusive de 0 — sonder les bornes (−2, 0, +2).
- Multi-joueurs : round-robin sans notion de « tous ont fini la manche X » — sonder un joueur qui finit avant les autres.

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/bobs-27.md` (canonique : D1..D20 **+ Bull**, parfait 1437). **Tester engine vs canonique.**
- **Divergences canonique↔engine (voir bobs-27.md §7)** : **D-1 (P1) — manche bull finale absente** (`engine:123` finit à `roundNum >= 20`) → max atteignable **1287**, donc le « 1437 » des règles in-app est **inatteignable** ; **D-2 (P2)** — texte `rulesBobs27HowB2` « 20 rounds » contredit son propre 1437. Décision mainteneur : ajouter la manche bull OU corriger le texte à 1287.

### 4.7 Checkout Practice

**Charte exploratoire** — *Missions*

1. **Quota multi-succès fini.** `target_successes` ∈ {1,2,3,5,10,20} : `practice_successes` s'incrémente à chaque checkout, drill fini *exactement* à `practice_successes >= target_successes`, `GameCompleted` à `TurnEnded` (jamais sur le dart de checkout). Sonder le franchissement de seuil et la séquence `DartThrown → TurnEnded(reason='checkout') → GameCompleted`.
2. **Mode infini (∞).** `target_successes == null` : enchaîner des checkouts sans auto-complétion quel que soit le compteur ; seul « End Drill » termine (sans gagnant).
3. **Réinitialisation à 170 entre tentatives.** Après un checkout (`score` laissé à 0), le `TurnStarted` suivant remet `score` ET `turn_start_score` à 170. Cibler checkout → tentative → **bust** : le bust revert à 170 (pas 0) et ne bloque pas les checkouts futurs.
4. **Double-out & finitions invalides.** Checkout valide (double, `==0`) ; finition non-double ; dépassement (`<0`) ; atterrissage sur 1. Non-double/overshoot = **bust** (revert à `turn_start_score`, aucun incrément de `darts_thrown` ni `practice_successes`).
5. **Parité des rails + End Drill à tout moment.** Rejouer 1–4 en manuel puis sim. « End Drill » à divers moments (turn actif, mi-tour, après checkout, score 170) → fermeture propre sans gagnant, aucun `DartThrown` post-complétion.

**Heuristiques**
- Seuil du quota : tester `target-1` / `target` / `target+1` succès.
- Le checkout n'émet PAS `GameCompleted` (décidé à `TurnEnded`, #254).
- `score == 0` transitoire entre checkout et `TurnStarted` suivant ; aucun dart intercalé ne fige ce 0.
- Bust ≠ comptabilisé (ni `darts_thrown`, ni `practice_successes`) mais enregistré dans `dartThrows` (padding sentinelle) pour le replay.
- Frontières double-out : 0-sur-double = checkout ; 0-sur-simple/triple = bust ; 1 = bust ; <0 = bust. DB (50) = checkout valide vs SB (25) sur 0 = bust.
- Gagnant : quota → joueur, ∞/End Drill → aucun. Solo uniquement (pas de rotation).

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/checkout-practice.md` (mode quota multi-succès — réaligné #585).

### 4.8 Count Up

**Charte exploratoire** — *Missions*

1. **Accumulation pure & absence de bust.** Chaque dart ajoute `segment × multiplier` sans décrément ni borne (MISS=0, SB=25, DB=50) ; scores énormes (T20×3 sur 20 rounds) → pas de plafond, monotonie non-décroissante (Table D, §6).
2. **Tour toujours à exactement 3 darts.** Fin de tour SEULEMENT au 3e dart, jamais sur MISS, jamais à mi-tour, jamais de win précoce. Tenter 4e dart / `TurnStarted` en plein tour → rejet (Tables C/F, §7.1).
3. **Fin par cap de rounds & comptage exact.** Dernier dart du dernier competitor du round `total_rounds` (8/12/16/20) → `LegCompleted` puis `GameCompleted` ; invariant `DartThrown total == competitors × total_rounds × 3` ; aucun event accepté après `GameCompleted`.
4. **Sélection du vainqueur & rotation.** Solo (vainqueur quel que soit le score), 2 joueurs avec écart, ≥3 en égalité au sommet (winner=null) ; rotation `current_turn_index` 0→n-1→reset + `current_round += 1` (Table H/J).
5. **Handicap comme score de départ.** Handicaps hétérogènes ({0,50,100,150,200}) : score initial = handicap, `score ≥ handicap` toujours, pas d'effet croisé ; handicap décisif sur le vainqueur (Table A, §7.6).

**Heuristiques**
- Comparer les deux rails pour chaque mission (score affiché / état / events).
- Compter les darts : `0 ≤ darts_in_turn ≤ 3` ; total final == `competitors × total_rounds × 3`.
- Monotonie : un score qui baisse (MISS, undo) contredit §6 — chercher à le provoquer.
- Frontières de round : passage dernier-competitor → reset index + round++ ; `1 ≤ current_round ≤ total_rounds`.
- Ordre des events de fin : `LegCompleted` DOIT précéder `GameCompleted`.
- Égalités au sommet (et à 1 pt près) → `winner = null`, sans sudden-death.
- SB vs DB (25 vs 50, pas 50/100) ; oracle = stats X01 moins checkout (aucune métrique de checkout, §9).

- **Cas scriptés critiques** — _[à remplir : passe 2]_
- **Cas-limites** — _[à remplir]_
- Oracle : `docs/games/count-up.md`.

---

## 5. Transverses (tous jeux)

> Vérifiés une fois sur 1-2 jeux représentatifs plutôt que par jeu.

- **Undo** — y compris franchissement de frontière de tour ; bouton désactivé quand rien à annuler.
  _[à remplir]_
- **Correction (`DartCorrected`)** — band → sheet ; segment réel affiché (auto), recompte des
  marks par cible (cricket) ; replay-aware (skip de l'original). _[à remplir]_
- **Replay après reload** — recharger en pleine partie → état restauré à l'identique. _[à remplir]_

---

## 6. Mapping vers les specs `e2e/` existantes

> Auditer la validité de chacune (post-réalignement doc) et étendre plutôt que dupliquer.

| Spec | Couvre | Statut à auditer |
|---|---|---|
| `e2e/cricket_3players.spec.ts` | Cricket 3 joueurs | _[à auditer]_ |
| `e2e/x01_auto_score_correction.spec.ts` | X01 + correction (sim) | _[à auditer]_ |
| `e2e/auto_scorer_sim.spec.ts` | sim bridge smoke | _[à auditer]_ |

---

## 7. Sortie

- Candidats régression à coder en `@playwright/test` — _[liste produite après passe 2]_
- Findings correctness → carnet `docs/testing/findings-2026-06.md` (à créer) selon le format du plan §8.
