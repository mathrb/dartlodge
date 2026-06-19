# Carnet de findings — cycle de vérification pré-1.0 (2026-06)

> **Carnet vivant.** Toutes les observations de la phase d'exécution atterrissent ici, dans le
> format ci-dessous. Les issues GitHub sont créées **par lot, après revue ensemble** — jamais au fil
> de l'eau, jamais sans feu vert explicite. Convention : `docs/plans/2026-06-19-1.0-verification-plan.md` §8.

---

## Convention

**Format d'un finding**
```
### F-NNN — <titre court symptôme>
- Axe        : Correctness | UX | Design | Données | i18n
- Surface    : <jeu/écran de l'inventaire (plan §2)>
- Rail       : web | device
- Sévérité   : P0 | P1 | P2
- Observé    : <ce qui se passe>
- Attendu    : <ce qui devrait + oracle/réf>
- Preuve     : <screenshot / étapes de repro / spec>
- Statut     : à trier | à confirmer | confirmé | issue #N | won't-fix (raison)
```

**Sévérité** — **P0** sortie utilisateur fausse / flux cœur cassé · **P1** incohérence
correctness/archi ou UX/design dégradant · **P2** hygiène/polish.

**Règle anti-faux-positif** — un finding est une *hypothèse*. Avant promotion en issue : confirmer
la repro **ET** vérifier l'oracle. « Won't-fix + documenter le scope » est un statut valide.

**Finding → issue** — symptôme seul (pas de cause/fix), section « Avant implémentation » forçant un
`/plan`, sous-issues natives si epic. Création **par lot après revue**.

**Finding → régression** — un finding P0/P1 reproductible en web devient une spec `@playwright/test`
dans `e2e/`.

**Cycle de vie du statut** : `à trier` → (repro + oracle) → `confirmé` / `won't-fix` → (revue + sign-off) → `issue #N`.

---

## Index

| ID | Axe | Sévérité | Titre | Statut |
|----|-----|----------|-------|--------|
| F-001 | Correctness | P1 | Bob's 27 — score parfait 1437 inatteignable (manche bull absente) | issue #588 (confirmé live : run parfait = 1287) |
| F-010 | Correctness | P1 | Cricket — Turn Breakdown (historique) ignore DartCorrected → fléchette périmée + marks faux | confirmé (live + code) |
| F-011 | UX | P2 | Bob's 27 — fin sur score≤0 sans cadrage « busted/perdu » | confirmé |
| **F-012** | **Correctness/UX** | **P0** | **Shanghai multi-joueurs : fin naturelle ne complète jamais → board soft-lock (irrécupérable)** | **confirmé (live ×2 + code)** |
| F-015 | Correctness/Données | P1 | Checkout Practice — fléchettes bustées comptées dans DARTS (spec §4/§6 vs projection) | confirmé |
| F-013 | UX | P2 | Count-Up sans DartInputSink → sim/auto-scoring inerte (probt intentionnel) | confirmé |
| F-014 | UX | P2 | Count-Up — NEXT termine le tour <3 fléchettes sans garde (auto-MISS-fill) | confirmé |
| F-016 | UX | P2 | Checkout — headline « N OF M » : M = tentatives, pas le quota configuré | confirmé |
| F-017 | UX | P2 | Checkout — readout « turn points » = somme brute (180) sur tour busté | confirmé |
| F-018 | i18n | P2 | Shanghai — texte règles « solo » alors que jeu multi-joueurs (D-1) | confirmé |

> F-006 (Count-Up non localisé) : **confirmé live + source** (était « à confirmer »).

**Issues GitHub créées (lot 2026-06-19)** : F-001→#588 · F-012→**#595** (P0) · F-006→#596 · F-010→#597 · F-015→#598 · F-009→#599 · F-011→#600 · F-013→#601 · F-014→#602 · F-016→#603 · F-017→#604 · F-018→#605 · F-020→#610. **Axe 5** : F-021→#612 (englobe F-007/F-008) · F-022→#613 · F-023/F-024/F-026→#614. _(F-003 infirmé, pas d'issue.)_

**Findings confirmés SANS issue (candidats)** : **F-002** (DB-error string brut), **F-005** (heatmap sans légende). **À confirmer avant issue** : F-004 (loading non uniforme), F-019 (heatmap lavage bleu), F-025 (es/pt split score).
| F-002 | Design | P2 | Surface DB-error = string brut non stylé | confirmé (live) |
| F-003 | Design | P2 | Incohérence empty-state (spacing 8 vs 16, titre body vs titleLarge) | infirmé (marginal, won't-fix) |
| F-004 | Design | P2 | Loading non uniforme (skeleton Players vs spinner History/Stats) | à confirmer |
| F-005 | Design | P2 | Heatmap sans légende/échelle ni numéros de segments (gap oracle DESIGN_SYSTEM §7.6) | **confirmé (live)** |
| F-019 | Design | P2 | Heatmap : faible densité tinte tout le plateau en bleu (lisibilité réduite ; données éparses) | à confirmer (conf. basse) |
| F-020 | Correctness/Données | P1 | X01 : fléchettes bustées comptées dans le PPR par-partie + BEST carrière (incohérent avec AVERAGE + §5.2) | issue #610 |
| F-021 | i18n | P2 | Lacune de localisation large : sous-titres cartes Home + libellés stats/post-game non traduits | confirmé (live DE+NL) |
| F-022 | i18n | P2 | nl : `achievementWins10/50/100Description` = « Win N games » (phrase EN non traduite) | confirmé |
| F-023 | i18n | P2 | fr : `historyRoundBreakdown` = « manches » (terme faux + incohérent, devrait être « tours ») | confirmé |
| F-024 | i18n | P2 | fr : `achievementNineDarterDescription` = « manche » (devrait être « leg », incohérent) | confirmé |
| F-025 | i18n | P2 | es/pt : split « Puntos/Pontos » vs « Puntuación/Pontuação » (intentionnel ?) | à confirmer (conf. basse) |
| F-026 | i18n | P2 | fr : `gameAdvanceTurnBody` « que 1 fléchette » (idiome « qu'une ») | confirmé (cosmétique) |
| F-006 | i18n | P2 | Count-Up board non localisé (chaînes en dur, clés existantes) | à confirmer |
| F-007 | i18n | P2 | `ErrorRetryWidget` « Retry » en dur (~10 pages prod) | à confirmer |
| F-008 | i18n | P2 | `home_page` Settings semanticLabel/tooltip en dur | à confirmer |
| F-009 | Design | P2 | Page Stats : header logo « DARTLODGE » vs header titré (Players/History) | à trier (confidence basse) |

---

## Axe 1 — Correctness

### F-001 — Bob's 27 : le score parfait documenté (1437) est inatteignable
- Axe : Correctness
- Surface : Bob's 27 (board + écran de règles)
- Rail : web
- Sévérité : P1
- Observé : les règles in-app annoncent un parcours parfait à 1437 ; la partie s'arrête après Double 20, max atteignable = 1287.
- Attendu : oracle `docs/games/bobs-27.md` — Bob's 27 canonique termine sur une manche Double Bull (1437). Résolution (ajouter la manche bull vs corriger le texte) = décision mainteneur.
- Preuve : `stateless_bobs_27_engine.dart:123` (`roundNum >= 20`) ; règles `rulesBobs27WinningBody`/`HowB2`.
- Statut : **issue #588** — **confirmé en live** : run parfait joué = FINAL SCORE **1287**, fin à ROUND 20/20, aucune manche bull.

### F-010 — Cricket : le Turn Breakdown de l'historique ignore les corrections (DartCorrected)
- Axe : Correctness (+ Données)
- Surface : History → Game Detail → tableau Turn Breakdown
- Rail : web
- Sévérité : P1
- Observé : un tour où une fléchette a été annulée+re-lancée (T20, 5, single-19 → undo single-19 → T19) s'affiche « T20 5 19 », MARKS = 4 dans le breakdown ; alors que le board live, l'AVG MPR post-game (6) et les mark-buckets reflètent la correction (T19, 6 marks). Seul le Turn Breakdown montre la fléchette périmée.
- Attendu : le breakdown doit refléter la fléchette corrigée comme toutes les autres surfaces. `TurnBreakdownBuilder.build` (`lib/features/history/domain/turn_breakdown.dart`) traite chaque `DartThrown` SANS gérer `DartCorrected`/supersession, contrairement à `PlayerStatsAssembler.fromEvents` (qui strippe les `original_event_id`/`superseded_event_ids`). **Viole le contrat CLAUDE.md** : « Any replay-aware code path … must collect these and skip the originals ». Risque aussi de corrompre le `runningTotal` rejoué pour tout tour contenant une fléchette annulée.
- Preuve : `exec-cricket-17.png` (row « Alice 2 4 T20 5 19 ») vs board `exec-cricket-11.png` (19 fermé = 3 hits) + post-game MPR 6.
- Statut : **confirmé (live + lecture code)** — candidat issue (P1)

---

## Axe 2 — UX / flux

### F-011 — Bob's 27 : fin sur score ≤ 0 sans cadrage « busted/perdu »
- Axe : UX
- Surface : Bob's 27 post-game
- Rail : web
- Sévérité : P2
- Observé : l'écran de fin est une carte neutre « FINAL SCORE / ROUND n/20 » (DONE + PLAY AGAIN), sans label win/lose/busted — identique pour une fin normale (round 20) et une fin anticipée sur score ≤ 0.
- Attendu : un signal distinct pour la fin anticipée « zéro » (cf. oracle bobs-27.md §7 D-3) — à confirmer comme intentionnel ou non.
- Preuve : `exec-bobs27-03.png`.
- Statut : confirmé (mineur)

### F-009 — Page Statistiques : header logo au lieu d'un titre d'écran
- Axe : Design / UX (cohérence inter-écrans)
- Surface : Statistics (root / player-picker)
- Rail : web
- Sévérité : P2 (confidence basse — possiblement intentionnel)
- Observé : la page Stats affiche le logo « DARTLODGE » en header, alors que Players et History affichent un header **titré** (« Players » / « History »).
- Attendu : cohérence de traitement des headers — OU confirmer que le logo est intentionnel pour la page « hub » Stats.
- Preuve : `exec-03-stats-empty.png` (header DARTLODGE) vs `exec-01-players-empty.png` / `exec-02-history-empty.png` (titrés).
- Statut : à trier

### F-012 — Shanghai multi-joueurs : la fin naturelle ne complète jamais (soft-lock irrécupérable) — **P0**
- Axe : Correctness / UX
- Surface : board Shanghai (`practice_board_page`) ; `active_practice_provider._advanceTurn` ; `stateless_shanghai_engine`
- Rail : web
- Sévérité : **P0**
- Observé : partie 2 joueurs, 7 rounds, jouée proprement. Après le tour round-7 du 2ᵉ joueur, **pas de post-game** : board bloqué sur « ROUND 8 / 7 », inputs morts (« dart not thrown » persiste, NEXT désactivé), `is_complete=false`, **et même « End Game » → confirm ne navigue pas**. Irrécupérable. Reproduit 2×.
- Attendu : plus haut score gagne en fin de round final → post-game (oracle shanghai.md §5).
- Cause (code) : l'engine Shanghai `apply('TurnEnded')` renvoie l'état avec `isComplete=true` **mais sans** `outcome: LegOutcome.gameCompleted` ; `_advanceTurn` (~ligne 341) gate la complétion sur cet outcome → la saute et émet un TurnStarted pour un compétiteur « suivant » fantôme (round 8). Catch40 met l'outcome (→ marche) ; le Shanghai instant-win passe par le chemin DartThrown (→ marche). Les tests ratent : ils pré-règlent `practiceRound:8` et font finir l'index-0, jamais une vraie rotation jusqu'à la fin.
- Preuve : trace tours 1–14 puis board figé « ROUND 8/7 BOB'S TURN » (inputs `generic` non-interactifs).
- Statut : **confirmé (live ×2 + lecture code)** — **candidat issue P0**

### F-015 — Checkout Practice : fléchettes bustées comptées dans le total DARTS — **P1**
- Axe : Correctness / Données
- Surface : post-game Checkout Practice (`practice_summary_widget._buildCheckoutHero` ← `legCompetitorStatsFromEvents`)
- Rail : web
- Sévérité : P1
- Observé : 2 checkouts (3 darts chacun) + 1 tour busté (3 darts) → **DARTS = 9**.
- Attendu : oracle checkout-practice.md §4/§6 « une fléchette bustée n'incrémente pas darts_thrown / ne compte que les non-bustées » → **DARTS = 6**.
- Cause : l'engine enregistre la fléchette de bust dans `dartThrows` (intentionnel, replay — comme X01) ; la projection `legCompetitorStatsFromEvents` compte tous les `DartThrown` sans filtre bust. Spec et projection se contredisent.
- Preuve : `exec-checkout-04-postgame.png` (DARTS 9).
- Statut : confirmé — candidat issue (P1) ; trancher spec vs projection

### Vague 2 — autres findings P2
- **F-013** — Count-Up board ne bind pas `DartInputSink` → `dartlodgeSim.emit` inerte + auto-scoring caméra mort sur Count-Up (probablement intentionnel : count-up manuel-only). À confirmer comme voulu.
- **F-014** — Count-Up : NEXT termine le tour avec <3 fléchettes (auto-remplit MISS), sans garde → un user peut forfaiter des fléchettes par erreur. Pas un bug de score (invariant darts préservé via MISS-fill), garde UX manquante.
- **F-016** — Checkout post-game headline « 2 OF 3 CHECKOUTS » : le dénominateur = tentatives, pas le quota configuré (2) → potentiellement confus.
- **F-017** — Checkout : readout « turn points » du status bar montre la somme brute (180) sur un tour busté (le score reste correctement à 170). Cosmétique.
- **F-018** — Shanghai : `rulesShanghaiWinningBody` dit « Played solo … no opponent » alors que le jeu est multi-joueurs (canonique + engine). Corriger le **texte** (i18n), pas l'engine.

---

## Confirmations positives — passe 1 (X01, axes 1+2, 2026-06-19)

> Vérifié en exécution réelle (Pixel 6a portrait, build release, sim bridge). **Aucun défaut** sur ces points.

- **États vides** (Players / History / Stats) : propres, cohérents, on-brand (icône 64px + titre + CTA/hint). → **F-003 (spacing 8 vs 16) infirmé visuellement** : pas de différence perceptible, marqué won't-fix.
- **Scoring X01** : 501 − T20×3 = 321 ; undo → 381 (cohérent band/score) ; checkout T20+T19+D12 → 0.
- **9-darter** : 9 fléchettes (l'undo exclut bien la fléchette annulée du compte), AVG PPR = 167 (= 501×3/9).
- **Buckets** : 180s = 2, 140-179 = 1 (mutuellement exclusifs, le 141 ne double-compte pas) ; CHECKOUT 100 % ; BEST OUT 141.
- **Nav post-game** : checkout → écran de fin (winner, breakdown) correct.
- **Succès** (axe 4) : First 180 + First Win + **Nine-Darter** débloqués et datés ; Big Fish correctement **non** débloqué (141 ≠ 170) ; progress « 100 Games of 501 » = 1/100.
- **Sim bridge** opérationnel dans le build release (prérequis passe 2 confirmé).

### Vague 1 — Cricket / Bob's 27 / Catch 40 (agents parallèles, 2026-06-19)
- **Cricket** : fermeture des marks (hits cap 3), overflow standard sur nombre fermé avec adversaire ouvert (T20→+60), **Bull = 25/mark (pas 50 pour DB)**, #569 in-game (segment hors-cible affiché mais 0 mark), undo in-game cohérent, rotation, leg→post-game, stats per-game/leg cohérentes. ✅ (seul défaut = F-010, spécifique à l'historique + correction).
- **Bob's 27** : start 27, cible D{n}, +2n/hit, −2n sur blanchissage, solo. ✅ (défauts = F-001/#588 + F-011).
- **Catch 40** : **conforme au canonique de bout en bout** — 61→100 (40 cibles), 2-dart=3pts / 3-dart=2 / 4-6=1, **exception 99→3pts**, max 120, bust-reset (checkout exige un double), fin de drill solo sans gagnant, apparition en History. ✅ **Aucun défaut.**

### Vague 2 — ATC / Shanghai / Count Up / Checkout (agents parallèles, 2026-06-19)
- **Around the Clock** : **aucun défaut** — progression 1→20, variantes standard/reverse/**doublesOnly** (seul mult==2 avance), Bull/MISS ignorés, hors-séquence ne fait pas avancer (fléchette comptée), >3 darts rejetés, victoire immédiate mid-turn, rotation multi-joueurs + cibles indépendantes, undo, post-game, labels de variante en historique. ✅
- **Shanghai** : scoring round×mult sur le numéro du round, **instant-win Shanghai** (S+D+T même tour) fonctionne de bout en bout, 3 hits sans les 3 multiplicateurs ≠ Shanghai, rotation, round cap 7 configurable. ✅ (défauts = F-012 P0 sur la fin naturelle + F-018 texte).
- **Count Up** : additif sans bust ni borne, MISS=0/SB=25/**DB=50**, tour = exactement 3 fléchettes, rotation + round++ après dernier joueur, fin après round 8, winner=plus haut score, buckets + PPR (sans checkout) corrects, invariant darts = comp×rounds×3. ✅ (défauts = F-006 P1 + F-013/F-014 P2).
- **Checkout Practice** : start 170, quota {∞,1,2,3,5,10,20}, checkout sur double incrémente succès, **reset 170** au tour suivant, complétion exacte au quota, bust → revert 170 sans incrément. ✅ (défauts = F-015 P1 + F-016/F-017 P2).

### Axe 3 — Design (passe solo, thèmes clair + sombre, 2026-06-19)
> Capture + inspection contre les checklists de `axis-3-design.md`. **Design solide, aucun nouveau finding.**
- **Thème clair** : Home, board X01 (score `onSurface`, nom `primaryFixed` mint, 50 BULL mint, grille sans overflow), post-game (trophée/héro/breakdown), History (carte badge+trophée), Stats (PPR 167, solo exclu des legs #106), Settings, états vides — tous propres et token-compliant. ✅
- **Thème sombre** : Home + Stats re-capturés — parité parfaite (fond sombre, accents mint, texte clair, contraste OK). ✅
- **F-009 re-confirmé** (header Stats = logo « DARTLODGE », pas titré comme Players/History). **F-002 confirmé** (surface DB-error = string brut non stylé).
- **Heatmap (vérifiée live, après extension sim-bridge x/y #607)** : un 9-darter joué avec coordonnées (`emit('T20', x, y)`) **peuple la heatmap** au post-game → chemin complet x/y validé (sim → submitDart → payload → dart_throws → getDartPositions → rendu). Le dartboard auto-dessiné + densité KDE s'affichent (hotspot rouge où les fléchettes clusterisent). **F-005 confirmé** (pas de légende/numéros) ; **F-019** (lavage bleu basse densité, conf. basse). ✅ chemin OK.
- **Reste de l'axe 3** : camera-first (#477) — vérifier si le chrome bascule sur web (cameraPreview possiblement null sans stub builder) ; cohérence inter-écrans (largement OK).

---

## Axe 3 — Design visuel

> Candidats **pressentis** (analyse code passe 1) — à confirmer visuellement sur screenshot avant toute issue.

### F-002 — Surface DB-error : string brut non stylé
- Axe : Design (+ i18n, cf. F-?)
- Surface : surface d'échec d'ouverture de la base (`app.dart` branche `error:`)
- Rail : web
- Sévérité : P2
- Observé : `Center(child: Text('Database failed to open: $e'))` — pas d'icône, pas de thème, pas de retry ; `$e` brut exposé. (Vu sur device pendant la validation résolution Pixel 6a.)
- Attendu : surface d'erreur stylée (icône + message borné + thème), cf. dimension « états transitoires ».
- Preuve : capture de la validation résolution (DB stale) — string brut centré, sans icône/thème/retry ; `lib/app/app.dart:~38`.
- Statut : **confirmé (vu live)** — candidat issue P2 (recoupe l'i18n F-006/DB-error)

### F-003 — Incohérence visuelle des empty-states
- Axe : Design
- Surface : Players / History / Stats (états vides)
- Rail : web
- Sévérité : P2
- Observé : gap icône→label 16dp (Players/Stats) vs 8dp (History) ; titre History en body vs `titleLarge` ailleurs.
- Attendu : empty-states cohérents (typo titre + rythme) — `axis-3-design.md` §2.7.
- Preuve : `exec-01-players-empty.png` / `exec-02-history-empty.png` — visuellement cohérents.
- Statut : **infirmé** — la différence de code (8 vs 16dp) n'est pas visuellement perceptible ; won't-fix.

### F-004 — Loading non uniforme
- Axe : Design
- Surface : Players / History / Stats (chargement)
- Rail : web
- Sévérité : P2
- Observé : Players a un skeleton façonné, History/Stats un simple spinner.
- Attendu : traitement loading cohérent inter-écrans.
- Preuve : _[capture passe 2]_
- Statut : à confirmer

### F-005 — Heatmap sans légende/échelle de couleur
- Axe : Design (gap oracle)
- Surface : Heatmap (post-game + stats)
- Rail : web
- Sévérité : P2
- Observé : le widget ne dessine ni légende/échelle ni numéros de segments, alors que `DESIGN_SYSTEM.md` §7.6 mentionne une « légende lisible ».
- Attendu : trancher — ajouter la légende OU corriger l'oracle.
- Preuve : `heatmap_dartboard_widget.dart` ; DESIGN_SYSTEM §7.6 ; **vu live** (`hm-postgame-scrolled.png` — heatmap rendue sans légende ni numéros).
- Statut : **confirmé (live)**

### F-019 — Heatmap : faible densité tinte tout le plateau en bleu
- Axe : Design
- Surface : Heatmap (post-game)
- Rail : web
- Sévérité : P2 (confidence basse)
- Observé : avec 9 fléchettes positionnées, la densité KDE basse tinte la quasi-totalité du plateau en bleu (le board sous-jacent — segments/anneaux — est lavé de bleu), réduisant sa lisibilité ; seuls les hotspots ressortent.
- Attendu : checklist axe 3 §2.6 — « la traîne basse densité s'estompe vers transparent, pas de plancher dur ». À revoir avec un jeu de données plus dense (possiblement normal pour 9 fléchettes éparses).
- Preuve : `hm-postgame-scrolled.png`.
- Statut : à confirmer (conf. basse) — revoir avec plus de fléchettes

---

## Axe 4 — Données / persistance

### F-020 — X01 : les fléchettes bustées sont comptées dans le PPR par-partie et le BEST PPR carrière
- Axe : Correctness / Données
- Surface : post-game X01 (AVG PPR) + page Stats X01 (PPR → BEST)
- Rail : web
- Sévérité : P1
- Observé : partie 501 avec un tour busté (180,180,[bust depuis 141],141) → AVG PPR **170.3** sur 12 darts (= 681/12×3, le tour busté crédité 180) ; BEST PPR carrière aussi 170.3. Or l'**AVERAGE PPR carrière = 143.1** est correct (busté = 0) → **deux conventions de bust sur le même écran**.
- Attendu : x01.projections.md §5.2 « bust turns score = 0 » → PPR = 501/12×3 = **125.25** (numérateur exclut les points bustés, dénominateur garde les 3 fléchettes).
- Cause : `gameStatsFromEvents` somme `dart_throws.score` brut ; `X01BestLegPprProjection` inclut délibérément les busts (commentaire périmé renvoyant à `X01AverageProjection`, qui depuis #318 les EXCLUT via `turn_score`). Possiblement une divergence doc↔code (#246) → réconcilier (corriger le code à bust=0, OU amender §5.2 + le commentaire).
- Preuve : `a4stats-04-postgame2.png` (170.3/12), `a4stats-05-career.png` (AVERAGE 143.1, BEST 170.3).
- Statut : **issue #610**

### Confirmations positives — Axe 4 (agents parallèles, 2026-06-19)
- **Stats** : 9-darter 167, buckets mutuellement exclusifs ; **agrégation cross-game + ordering `(game_id, local_sequence)` corrects** (carrière 143.1 = combiné des 2 parties — si l'ordering était cassé, les `local_sequence` qui se chevauchent corromptraient le total) ; #106 (parties solo exclues des legs carrière mais comptées en Games Played) wiré correctement.
- **History** (6 parties mixtes) : liste `end_time` DESC, seulement complétées ; filtres type + plage de dates (narrow/clear) ; detail leg-breakdown = match exact du jeu (X01 301 hand-checké) ; labels MPR/PPR par gameType ; read-only. Pagination NON exercée (6 < 20).
- **Achievements** : 9-darter → First180/First Win/Nine-Darter datés, Big Fish correctement verrouillé, 100-Games 1/100 ; **idempotence reload confirmée** (pas de re-toast, dates conservées) ; 2ᵉ partie → progress 1→2, aucun re-toast.
- **Persistance/replay** : reload mid-game → état restauré **exact** (score/round/joueur/darts) ; undo cohérent ; DartCorrected recompute correct ; partie terminée read-only + URL active redirige vers post-game ; reload post-complétion reste complétée.
- **Observations mineures (non élevées)** : 2 erreurs console transitoires au START d'un X01 (non investigué) ; après un reload navigateur, le hash-route revient à Home (l'état est préservé/rejouable mais la deep-link n'est pas auto-restaurée — comportement release attendu ; à vérifier : existe-t-il une affordance « reprendre la partie en cours » côté UI ?).

---

## Axe 5 — i18n

> **Exécution (agents parallèles, 2026-06-19)** : débordement DE+NL (runtime), jargon (web+ARB), pluriels/cohérence (ARB).

### F-021 — Lacune de localisation large (Home + stats/post-game)
- Axe : i18n · Surface : Home, Stats, post-game, game detail · Rail : web · Sévérité : P2
- Observé (en DE et NL) : sous-titres des cartes Home (« STRATEGIC PLAY », « SHANGHAI, COUNT-UP », « IMPROVE SKILLS », « ANALYZE DATA », « SESSIONS », « ROSTER ») non traduits ; « STATISTICS BREAKDOWN », « CATEGORY » (alors que le tableau detail utilise « CATEGORIE » en nl → incohérent), « Need ≥2 games for a trend », onglet « Practice », chip config « Double Out » restent EN.
- Attendu : localiser ces chaînes (non-jargon). Superset de F-007 (`Retry`) / F-008 (home Settings).
- Preuve : `de-home.png`, `nl-settings.png`, `de-statsdetail.png`.
- Statut : confirmé (live DE+NL)

### F-022 — nl : descriptions de succès « Win N games » non traduites
- Axe : i18n · Surface : Achievements (nl) · Sévérité : P2
- Observé : `achievementWins10/50/100Description` = « Win 10/50/100 games » (phrase anglaise) ; les 5 autres locales le traduisent (de « Gewinne 10 Spiele », fr « Gagner 10 parties »…). nl seul outlier.
- Attendu : « Win 10 spellen/potjes ».
- Statut : confirmé

### F-023 / F-024 — fr : « manche » au lieu de « tour » / « leg »
- Axe : i18n · Surface : history detail / achievements (fr) · Sévérité : P2
- Observé : `historyRoundBreakdown` = « Détail des **manches** » (tout le reste fr utilise « tour » pour round ; « manche » = un set de legs, sémantiquement faux) ; `achievementNineDarterDescription` = « Gagner une **manche** de 501 » (tout le reste fr utilise le loanword « leg »).
- Attendu : « Détail des tours » ; « Gagner un leg de 501 ».
- Preuve : `app_fr.arb`. Source : darts-nerd.com/glossaire.
- Statut : confirmé (drift terminologique intra-langue)

### F-025 / F-026 — low-confidence (es/pt score split ; fr idiome)
- **F-025** : es/pt `historyColScore` = « Puntos »/« Pontos » vs « Puntuación »/« Pontuação » ailleurs — possiblement intentionnel (points-par-tour vs métrique agrégée). À confirmer.
- **F-026** (cosmétique) : fr `gameAdvanceTurnBody` branche `one` code « que 1 fléchette » au lieu de « qu'une fléchette ».

### Confirmations positives — Axe 5
- **Débordement DE+NL : AUCUN** sur toutes les surfaces atteintes (Settings, variant selection dont la **rangée 4-chips** EINSTIEG/AUSSTIEG/LEGS/RUNDEN, board, config, modals, stats, history). Ellipse checkout = gracieuse ; turn-breakdown = scroll horizontal by-design. *(Post-game/turn-breakdown DE non atteints — abandon route home.)*
- **Pluriels ICU** : 9 clés × 7 locales corrects (fr/pt count=0 → `one`/singulier OK ; pas de catégorie surnuméraire) ; **placeholders** tous présents + bien positionnés (réordonnancement fr/it vérifié) ; pas de double-espace.
- **Cohérence terminologique** : de/es/it/nl/pt propres (1 radical/concept) ; seul fr a les 2 « manche » (F-023/024).
- **Loanwords légitimes** (PAS des défauts) : de Name/System/Debug/Darts, nl Tips/VARIANT, it Round/Feedback, es Error ; checkout/leg/marks/180s/bull cohérents par locale.

---

> Candidats **pressentis** (analyse code passe 1, tableau d'offenders) — à confirmer en passe 2.

### F-006 — Count-Up board non localisé
- Axe : i18n
- Surface : Count Up board (`count_up_board_page.dart`)
- Rail : web
- Sévérité : P2
- Observé : seul board avec des chaînes en dur (« Error », « Game not found », « End Game », « Settings », « Undo last dart », « NEXT PLAYER »/« NEXT ROUND », semanticLabels) ; X01/Cricket/Practice sont localisés.
- Attendu : câbler `l10n.*` — les clés ARB existent déjà et sont consommées par X01 (`gameNotFound`, `commonError`, `gameMenuEndGame`, `settingsTitle`, `gameOptionsSemantic`, `gameUndoLastDart`, `gameNextPlayer`/`gameNextRound`). Aucune clé à créer.
- Preuve : `count_up_board_page.dart:84,92,133,146,150,279,287`.
- Statut : **confirmé (live + source, vague 2)** — candidat issue (P1) ; priorité si Count-Up est expédié

### F-007 — `ErrorRetryWidget` « Retry » en dur
- Axe : i18n
- Surface : widget partagé (~10 pages de prod)
- Rail : web
- Sévérité : P2
- Observé : `Text('Retry')` codé en dur ; widget réutilisé par de nombreuses pages.
- Attendu : libellé localisé.
- Preuve : `lib/core/widgets/error_retry_widget.dart:35,54`.
- Statut : à confirmer

### F-008 — `home_page` Settings semanticLabel/tooltip en dur
- Axe : i18n
- Surface : Home (bouton Settings)
- Rail : web
- Sévérité : P2
- Observé : `semanticLabel: 'Settings'` + `tooltip: 'Settings'` en dur (accessibilité non traduite) ; clé `settingsTitle` existe.
- Attendu : libellé localisé.
- Preuve : `lib/features/game/presentation/pages/home_page.dart:24,25`.
- Statut : à confirmer

> **Won't-fix présumés (à confirmer)** : surface auto_scorer (~33 chaînes, débogage/labo) ; acronymes
> darts (`PPR`/`MPR`/`MPT`) ; surface DB-error pré-`MaterialApp` (anglais acceptable, mais à documenter — voir F-002 côté style).

---

## Notes

- Les findings « à confirmer » proviennent de l'**analyse code de la passe 1**, pas d'une observation
  d'exécution — ils restent des hypothèses jusqu'à repro/screenshot en passe 2.
- F-002 et la partie « non localisée » de la surface DB-error se recoupent (design × i18n) — à traiter
  ensemble le cas échéant.
