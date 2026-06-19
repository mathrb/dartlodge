# Axe 2 — UX / flux — plan de test détaillé

> **Statut : SQUELETTE.** Charpente + oracles posés. Contenu rempli en 2 passes :
> (1) **charte exploratoire** par préoccupation, (2) **socle de parcours scriptés** (passe 2).
> Parent : `docs/plans/2026-06-19-1.0-verification-plan.md` §4. Mécanique d'exécution et
> template de cas de test : voir `docs/testing/axis-1-correctness.md` §2–§3 (réutilisés tels quels).

---

## 1. Objet & oracles

Vérifier que **l'utilisateur traverse chaque parcours sans se retrouver coincé, perdu, ou face à
un comportement surprenant**. On regarde les *transitions* et les *états*, pas le score (axe 1).

**Oracles :**
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` (flux & index des écrans — réaligné #585).
- `CLAUDE.md` — règles de navigation (`context.go()` vs `context.push()`, `PopScope`, `onExit`),
  gestion des 3 états `AsyncValue`, garde `_sawDartsThisTurn` de l'auto-advance, etc.
- Code : `lib/app/app_router.dart`, `lib/features/**/presentation/pages/*.dart`.

**Rail :** majorité `[web]` (Pixel 6a portrait 412×915) ; `[device]` pour back physique, haptique,
ressenti de l'assist caméra.

---

## 2. Mécanique & template

Identiques à l'axe 1 — voir `axis-1-correctness.md` §2 (rails manuel/sim, gotchas semantics,
viewport-only Pixel 6a) et §3 (template de cas de test). Une charte exploratoire = missions +
heuristiques, pas d'étapes figées.

---

## 3. Sections par préoccupation

> Chaque section : (a) **Charte exploratoire** [passe 1] — missions + heuristiques ; (b) renvoi
> vers les **parcours scriptés** concernés [passe 2].

### 3.1 Navigation & back

**Charte exploratoire** — *Missions*

1. **Spokes depuis Home.** Home → Stats / History / Players / Settings, puis back OS à chaque fois : chaque saut doit être `push` (back-poppable), le retour ramène à Home sans jamais quitter l'app.
2. **Chaînes profondes liste→détail→sous-détail.** Home → Stats → Player Stats → Achievements ; Home → History → game detail. Dépiler intégralement au back : chaque maillon revient d'un cran (pas de « téléportation » à Home).
3. **Resets de pile intentionnels (`go`).** Démarrage de partie, fin/abandon (board→Home), post-game→Home, suppression joueur / effacement données : après ces `go`, le back ne doit PAS ressusciter l'écran abandonné/supprimé.
4. **Piège `PopScope(canPop:false)` de la variant selection.** Marteler le back matériel : doit rediriger vers Home (jamais « rien », jamais quitter l'app).
5. **Garde `onExit` confirm-before-leave sur boards actifs.** Partie en cours : tout chemin de sortie (back OS, back navigateur, geste, menu) déclenche le dialogue de confirmation ; PAS quand la partie est déjà complète en base. Vérifier l'asymétrie Count Up (aucune garde `onExit`).
6. **Back qui saute un modal non acquitté.** Provoquer bust/leg/win/toast succès puis back OS → doit acquitter d'abord, pas filer à Home par-dessus.

**Heuristiques**
- Règle d'or `push` (forward navigable) vs `go` (reset assumé) ; une sortie d'app surprenante hors Home = symptôme.
- Source de vérité « partie complète » = la **base** (`GameRepository.getGame`), pas le notifier (`endGame/endDrill` n'écrivent pas `state.isComplete`).
- Annuler dans le dialogue `onExit` garde l'utilisateur sur place ; back navigateur ≠ back OS sur Flutter web (d'où `onExit`).
- Double-tap/spam du back ne dépile pas deux crans ni ne double-déclenche un `go`.
- Asymétries assumées (à reconnaître, pas signaler) : Count Up sans `onExit` ; Post-Game sans bouton retour (nav par boutons).

- Oracle : `UI_SCREEN_FLOWS_V3_FINAL.md` (Navigation Semantics) + règles `go`/`push`/`PopScope`/`onExit` de CLAUDE.md.

### 3.2 États non-heureux (vides / loading / erreur)

**Charte exploratoire** — *Missions*

1. **Vide vs chargement.** Sur les 4 écrans (Players, History, Stats, roster de setup), provoquer un chargement lent : on doit voir un *loading* (skeleton/spinner), JAMAIS « aucune donnée » pendant que la requête tourne. Zone suspecte : `player_selection_page` lit `playersAsync.value ?? []` AVANT le `when` (lineup/compteur peuvent afficher « 0 joueur » en chargement).
2. **Vides réels et actionnables.** Roster vide, history sans parties, stats sans partie jouée, lineup de setup vide : chaque vide est informatif + offre une sortie (CTA/hint), pas un cul-de-sac. Cas mixte : joueur sans partie → badge AVG / stats affichent 0/« — » propre (pas NaN/null/erreur).
3. **Erreurs récupérables.** Forcer une erreur (provider throw, `PlayerNotFoundException`) : chaque écran rend un message localisé + un retry qui `invalidate` et re-déclenche réellement la requête (guérissable).
4. **Échec d'ouverture DB.** Bannière « Database failed to open » plein écran : message actionnable (pas un `$e` brut), bloque proprement l'accès. Settings/locale en loading/erreur → fallback silencieux (locale système, thème), pas de crash.
5. **Zéro `.value!` non gardé.** Chasser tout chemin où un `AsyncValue` non-`data` ferait planter (ex. `ref.listen` board sur loading/erreur transitoire). Confirmer `AsyncValue.value` (pas `valueOrNull`).
6. **Transitions & re-déclenchements.** Empty→data via stream drift `.watch()` (passe au peuplé sans rebuild manuel) ; erreur→retry→loading→data ; filtre History sans résultat (vide *filtré* vs vide *réel*, reset présent) ; pagination (spinner pied de liste vs erreur page suivante).

**Heuristiques**
- « Never blank while busy » ; vide ≠ erreur ≠ chargement (3 rendus distincts, jamais collapsés).
- Tout vide a une sortie ; tout error a un retry *vivant* (localisé, re-tente réellement).
- Message d'erreur lisible — pas de fuite `$e`/stack à l'utilisateur.
- Drapeaux rouges : `.value!` non gardé, `valueOrNull`, lookups `async.value ?? default` avant `when`.
- Données partielles → placeholder via `StatFormatter`, jamais NaN/null.

- Oracle : conventions `AsyncValue` (data/loading/error) de CLAUDE.md + écrans listes/stats/history.

### 3.3 Modals & interruptions

**Charte exploratoire** — *Missions*

1. **Apparition au bon instant.** Chaque modal/notif se déclenche exactement sur sa transition : `showBust` (snackbar BUST X01/Catch-40), `pendingLegWinnerId` (LegCompleteModal), `pendingGameWinnerId`/`isComplete` (nav post-game), fin « busted » Bob's 27, snackbar « 🏆 » succès (#521/#527) — jamais en avance, jamais en double sur un seul franchissement.
2. **Acquittement obligatoire, aucun « blow past ».** Aucune modal `barrierDismissible:false` franchie sans action ; surtout aucun auto-advance board-clear ni NEXT ne la court-circuite. Garde CLAUDE.md : `advanceTurn()` no-op si `showBust || pendingLegWinnerId != null || pendingGameWinnerId != null || isComplete`. Asymétrie X01 (advanceTurn dismisse bust/leg) vs cricket (nextPlayer ne dismisse pas — la garde est l'unique filet) ; les 2 chemins (auto + NEXT) gardés identiquement.
3. **Empilement / co-occurrence.** Snackbar succès + modal de victoire à une partie record (9-darter qui gagne ET débloque) : ordre, lisibilité, pas de modale masquée par le barrier ; `ScaffoldMessenger` global sérialise les snackbars sans perdre le `showDialog`.
4. **Dismiss → bon état.** `dismissBust()` reprend sur le bon joueur ; `dismissLegModal()` enchaîne le leg suivant (pas re-déclenche) ; nav post-game ne réarme pas la modale ni ne laisse une snackbar orpheline.
5. **Reload en pleine célébration.** Recharger pendant un BUST / leg-complete / juste après complétion : replay reconstruit un état cohérent ; pas de modale fantôme re-déclenchée ni de succès re-notifié.

**Heuristiques**
- Ne croire qu'aux transitions `prev→next` exactes ; tester double-tap, throw rapide pendant l'animation, undo juste avant/pendant la modale.
- Un batch de succès = 1 son (`SoundCue.achievementUnlock`) mais N snackbars — vérifier ce ratio.
- Croiser modal × auto-advance × NEXT × menu End Game × back Android.
- Asymétrie X01/cricket = contrat (l'oracle est la garde, pas l'égalité de comportement).
- Snackbar succès via `messengerKey` global (survit la nav) vs modales board-locales (disparaissent à la sortie).
- Fidélité au replay : état reconstruit = état DB authoritative (`GameRepository.getGame`, pas le notifier).

- Oracle : flux bust/leg/win/busted + toast succès (#521) + garde auto-advance.

### 3.4 Undo & correction

**Charte exploratoire** — *Missions*

1. **Disponibilité/état du bouton undo.** Présent et lisible dans chaque board ; activé uniquement quand il y a quelque chose à annuler (`dartsThrownInTurn > 0` ou un compétiteur a lancé), grisé (`onTap:null`) en début de partie / 1er dart d'un tour vierge. Le grisé doit lire « rien à annuler », pas « bug ».
2. **Undo à travers une frontière de tour.** Annuler le 1er dart d'un nouveau tour : retour cohérent au joueur *précédent* (score/marks/dart restaurés), sans réattribuer au mauvais joueur. Multi-joueurs (≥3) + Crazy Cricket (`CrazyTargetsRolled` re-rolé ?). Hero, band, nom du joueur actif synchrones.
3. **Undo après un modal (bust / fin de leg).** Annuler après un bust : `showBust`/`pendingLegWinnerId` se réinitialisent, pas de modale fantôme ni d'undo qui saute une victoire non acquittée. Pas d'undo sur partie complète (`GameAlreadyCompleteException` → action non proposée).
4. **Flux de correction (band → sheet).** Taper un dart lancé ouvre une feuille ; le segment réellement détecté est visible avant correction (y compris cricket : vraie cible, non normalisée MISS) ; re-sélectionner met à jour score/marks immédiatement ; la feuille est *dismissable sans changement* (swipe / tap hors zone) ; slot vide → saisie manuelle (tour actif seulement).
5. **Undo d'un dart corrigé / corrections enchaînées.** Corriger puis annuler ; corriger 2× le même dart ; annuler juste après. L'undo cible le bon `DartThrown` non-corrigé (les `original_event_id` retirés sont sautés) ; aucune combinaison ne fige l'UI ni ne double-compte.

**Heuristiques**
- Découvrabilité : indice visuel distinguant slot lancé tapable / vide tapable / inerte.
- Réversibilité & non-destructivité : dismiss de la feuille ne modifie rien ; undo enchaînable jusqu'au début sans corruption.
- Never-stuck : après toute séquence undo/correction/modal, toujours un chemin avant (lancer/NEXT) et arrière.
- Cohérence inter-vues : hero / band / status bar / marks-checkout / nom joueur racontent la même histoire après undo/correction.
- Sérialisation (`_serializer.run`) : double-tap undo / tap-tap rapide ne dérègle pas l'état.
- Asymétrie auto (segment réel montré) vs manuel — intentionnelle, pas un bug.

- Oracle : `DartCorrected` (band → sheet) + dispo/désactivation du bouton undo.

### 3.5 Setup (joueurs / config / variante)

**Charte exploratoire** — *Missions*

1. **Atteindre une partie démarrable par catégorie.** X01 (501/301/701/901), Cricket (Standard/No Score/Cut Throat/Random/Crazy), Casual (Shanghai/Count-Up), Practice (ATC/Catch 40/Bob's 27/170 Checkout) : chaque variante mène à un board démarrable ; « Custom » (désactivé X01/Cricket) communique son indispo (opacité 0.38 + tooltip), jamais faussement navigable.
2. **Sélection joueurs = passerelle vers `canStart`.** Roster vide (« tap to add »), NEW PLAYER (nom vide, limite 24 car., doublons/erreurs repo remontés au champ), add/remove du lineup, auto-sélection du plus récent, plafond `maxPlayers` (≤6). Chasser tout START GAME désactivé sans raison visible, ou activé avec sélection invalide.
3. **Lineup actif : réordonnancement & handicap.** Drag-to-reorder (poignée, badge position), cohérence après add/remove, chip handicap (X01 négatif, Count-Up positif, masqué ailleurs) ; ordre + handicaps survivent jusqu'au board.
4. **Bottom sheet de config (pas une route).** Éditer selon le type (In/Out + legs/rounds X01 ; scoring×targetMode Cricket ; variante ATC ; rounds Shanghai/Count-Up ; target successes Checkout ; SET custom X01). Pattern draft copy-on-open (APPLY désactivé sans changement, dismiss = abandon) ; chip masqué quand rien d'éditable (Catch 40, Bob's 27) ; résumé fidèle.
5. **Back / PopScope à chaque étape.** variant_selection (`canPop:false` → pop sinon `go(home)`), player_selection (back → pop ; reset → home), bottom sheets. Back matériel == back visuel ; aucun piège ; aller-retour ne corrompt pas le setup.

**Heuristiques**
- Toujours-démarrable-ou-explicable : START GAME activé OU raison visible (tooltip/vide/chip désactivé) — pas d'impasse muette.
- CRUD-vérité : variante/joueurs/ordre/handicap/config choisis se retrouvent intacts dans le board.
- Bords : roster vide, exactement `maxPlayers`, dépassement, nom 0/24 car., SET 0/négatif/énorme, rounds ∞ vs fini, legs 1↔9.
- Draft de la sheet : APPLY inerte sans modif ; swipe/barrière ≠ APPLY ; réouverture repart de la config courante.
- « Last played » (X01/Cricket) reprend exactement la dernière config et court-circuite vers les joueurs.
- Asymétries de label scoring×targetMode / In·Out entre chip / « Last played » / header in-game / historique.

- Oracle : player selection, game config (bottom sheet), variant selection (`:category`), `canStart`.

### 3.6 Assist auto-scoring

**Charte exploratoire** — *Missions* (flux/UX, PAS précision modèle = device/probe)

1. **Bascule camera-first à l'activation.** `dartlodgeSim.enableAutoScoring()` fait passer chaque board au layout camera-first (`cameraFirst = autoScoringOn && cameraPreview != null`). Sur web le `CameraPreview` est stubbé → vérifier le **chrome** (band proéminente, `HeroMetricWidget`/strips, `GameStatusBarWidget(showDarts:false)`), pas l'image caméra.
2. **Darts émises = darts scorées.** `dartlodgeSim.emit('T20')` (→ `submitDart`) suit le chemin d'entrée du jeu : score appliqué, dart visible dans la band, séquence d'events identique au manuel. Couvrir `T20`/`D20`/`SB`/`DB`/`MISS`.
3. **Drop silencieux hors-turn / jeu fini.** `submitDart` best-effort (#538) : un dart émis sur un turn plein/terminé ou jeu complet est silencieusement ignoré (le tracker en avance ne coince pas le board).
4. **Auto-advance opt-in : gardes.** Opt-in défaut OFF (`autoAdvanceOnClearEnabledProvider`) ; `advanceTurn()` (sim : `dartlodgeSim.advance()`) no-op si modal bust/leg/win pending OU jeu complet, et bump `activeTurnSignal` comme NEXT.
5. **Correction d'un dart auto.** band→sheet : `DartCorrected` (`original_event_id`) supersède l'original, score recalculé, flux cohérent.
6. **Asymétrie auto vs manuel (Cricket).** Segment réel **affiché** (band/historique), seul le comptage marks gaté par cible — voulu, pas un bug.

**Heuristiques / frontière web↔device (explicite)**
- **Web (sim) couvre** : bascule camera-first chrome, `submitDart`, `advanceTurn` direct, correction.
- **Device-only / hors scope web** : `CameraPreview` live, détection board-clear réelle, focus ; le **confirm-before-clear** (`emptyFramesToRebaseline` ≈ 9 frames ≈ 3 s @ 3 Hz) et la garde `_sawDartsThisTurn` — `dartlodgeSim.advance()` BYPASSE ces gardes (contrôle direct), donc `shouldAutoAdvance` se vérifie en **test unitaire** + device, pas via le sim.
- Opt-in par défaut OFF : toujours établir l'état avant d'explorer l'auto-advance.
- « Jeu complet » autoritatif = `GameRepository.getGame`, pas le notifier.
- Mock = post-détection (injecte à `sink.submitDart`) : n'exerce ni tracker, ni cap 3-darts, ni board-clear.

- Oracle : confirm-before-clear, auto-advance opt-in (`_sawDartsThisTurn`), no-op si modal/jeu fini ; rail sim (`dartlodgeSim`).

### 3.7 Partie en cours (reload / exit / read-only)

**Charte exploratoire** — *Missions*

1. **Reprise après reload (replay fidèle).** Recharger à divers moments (X01/Cricket/practice) : état intégralement reconstruit par replay (`score`, joueur actif, round/`totalRounds`, darts du tour, cibles cricket, stratégie in/out). Aucune entrée mid-tour perdue ni dupliquée.
2. **Sortie menu → Home (jamais post-game).** « End Game » sur partie non terminée : confirme → écrit `is_complete=true` → route vers Home. `endGame/endDrill` n'écrivent PAS `state.gameState.isComplete` précisément pour que le listener post-game ne détourne pas la sortie menu. Atterrir sur `home`, pas `postGame`.
3. **Achèvement réel → post-game.** Partie gagnée pour de vrai (`gameState.isComplete` via le moteur) → `/post-game/:gameId`. Même mutation DB que mission 2, navigation opposée. Sonder le timing (modal non acquittée vs auto-advance) pour ne pas sauter la célébration.
4. **Garde `onExit` (toutes voies).** `onExit` s'exécute pour toute sortie (`go` interne, back/forward navigateur, geste OS) : dialogue sur partie non terminée, confirme=quitter / annule=rester ; lit la DB via `_gameIsComplete`→`getGame` (pas le notifier), donc partie déjà complète sort sans re-demander. Pas de double dialogue.
5. **Lecture seule depuis History.** Partie complétée ouverte depuis l'historique : aucune saisie, aucun undo, aucun NEXT (`canNext = !isComplete`) ; aucun `GameEvent` appendable.
6. **Reprise d'une partie en cours depuis ailleurs.** Quitter (Home) puis rouvrir : reprend exactement où arrêté, reste éditable tant que `is_complete=false`.

**Heuristiques**
- Symétrie/asymétrie de destination : même mutation DB (`is_complete=true`), deux nav divergentes (Home pour End Game, post-game pour victoire) — toute confusion = dump injustifié en post-game.
- Source de vérité du flag : DB (`getGame().isComplete`, lue par `onExit`) vs `notifier.state.gameState.isComplete` (listener nav) — incohérence = double dialogue / route ratée.
- Event stream : reload après une fléchette, en plein bust, sur frontière tour/round/leg, après undo → replay déterministe trié `(game_id, local_sequence)`.
- Read-only sans faille : traquer tout chemin résiduel de mutation sur partie terminée (sink camera-first, auto-advance, undo).
- Objectif premier : aucune partie en cours perdue ; aucun tour partiel non rejouable après reload/sortie.

- Oracle : reprise après reload (replay), sortie menu → home (pas post-game), partie terminée read-only (`onExit`/`_gameIsComplete`).

---

## 4. Socle de parcours scriptés (passe 2)

> Cas scriptés bout-en-bout, dérivés de la 1re passe exploratoire. _[à remplir : passe 2]_

Candidats pressentis :
- Parcours nominal Home → setup → partie → post-game → home, back testé à chaque étape.
- Reload en pleine partie → état restauré.
- Auto-advance opt-in : board clear émulé → tour avance sans sauter de joueur.
- États vides des 4 écrans principaux (joueurs, history, stats, roster de setup).

---

## 5. Mapping vers les specs `e2e/` existantes

| Spec | Couvre | Statut à auditer |
|---|---|---|
| _[à compléter en passe 2]_ | | |

---

## 6. Sortie

- Candidats régression `@playwright/test` — _[liste produite après passe 2]_
- Findings UX → carnet `docs/testing/findings-2026-06.md` (à créer) selon le format du plan §8.
