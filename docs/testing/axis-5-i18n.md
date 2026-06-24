# Axe 5 — i18n — plan de test détaillé

> **Statut : passe 1 (chartes exploratoires par préoccupation).** Traité **en dernier** (UI stabilisée
> par les axes 1-4). Cas scriptés / revue par locale = passe 2 (différée).
> Parent : `docs/plans/2026-06-19-1.0-verification-plan.md` §7. Mécanique : voir `axis-1-correctness.md` §2
> (viewport Pixel 6a 412×915) + bascule de langue via `localeSettingProvider`.

---

## 1. Objet & oracles

Vérifier que l'appli est correcte et soignée dans les **7 langues** (en/fr/de/es/it/nl/pt).
La **parité des clés est déjà auditée et parfaite** (515 clés × 7, 0 manquante/orpheline,
placeholders intacts — cf. `doc-drift-audit-2026-06-19.md`) → l'axe 5 cible ce que la parité ne couvre PAS.

- Oracles : `lib/l10n/arb/*.arb` (template `app_en.arb`), `lib/l10n/l10n.yaml` + `gen_l10n`,
  `lib/l10n/gen/app_localizations*.dart`, `test/l10n/arb_integrity_test.dart` (gate parité ARB↔ARB).
- Rail : `[web]` (bascule de langue + screenshots des 7 locales) ; `[device]` marginal.

---

## 2. Préoccupations

### 2.1 Clés manquantes / fallback au rendu
**Charte exploratoire** — *Missions*
1. **Aucune clé brute à l'écran.** Risque réel ≠ ARB (parité parfaite) mais **confusion clé-de-snapshot ↔ libellé** : les clés de projection (`x01_average`, `cricket.mpt`, slugs de variante, `GameType.name`) servent d'argument à un mapping ; un `orElse: () => key` afficherait l'identifiant. Cibler post-game, stats, heatmap, succès.
2. **Toute clé consommée existe dans l'ARB template.** Le gate `arb_integrity_test` compare ARB↔ARB, **pas** code→ARB. `nullable-getter: false` → un getter manquant casse la compil du `gen/` (donc régénérer + committer `gen/` en lock-step — CI ne lance pas build_runner).
3. **Bascule de langue runtime re-rend tout l'arbre.** Changer la langue depuis Settings doit propager à chaque écran monté (board, modales bust/leg, `AchievementNotificationHost`, snackbars, sheets) ; un libellé capturé dans `initState`/un champ reste figé. `_BootstrapApp` (pré-DB) n'a pas de `Localizations` — aucun texte localisable n'y transite.
4. **Résolution locale système + repli.** `resolveAppLocale` matche par `languageCode` seul, retombe sur `en` ; device en langue non listée (`ja`) → `en` propre ; variantes régionales (`pt_BR`, `de_CH`) → langue de base ; code stocké invalide → gracieux. Cardinalité cohérente : `kSupportedLocales` ↔ `supportedLocales` généré ↔ 7 ARB ↔ 7 `gen/` ↔ `kLanguageAutonyms`.

**Heuristiques** — gen_l10n retombe sur le template *silencieusement* (la parité parfaite masque ce risque pour une *future* clé) ; `orElse: () => key` = anti-pattern à débusquer ; libellé lu hors `build` (champ/`late final`) ne suit pas la bascule ; un autonyme manquant casse le sélecteur sans erreur.

### 2.2 Débordement de texte (Pixel 6a portrait 412×915)
**Charte exploratoire** — *Missions*
1. **Faire éclater les chips de config en DE/NL.** `_MetadataRow` (variant selection) : chips `setupChipIn/Out/Legs` dans un `Row` à espacement fixe, **sans `Flexible`/`maxLines`/overflow**. DE : `IN`→`EINSTIEG` (×2.67), `OUT`→`AUSSTIEG` → la rangée X01 (4 chips) déborde-t-elle (rayures) à 412px ?
2. **CTA ALL-CAPS à letterSpacing élevé.** `setupStartGame` (→`SPIEL STARTEN`), `gameNextRound` (→`NÄCHSTE RUNDE`), `gameNextPlayer` (→`NÄCHSTER SPIELER`), `setupApply` (→`ANWENDEN`) : le letterSpacing 1.0-1.2 amplifie la largeur — pas de troncature ni wrap qui casse la hauteur de barre.
3. **Le FittedBox(scaleDown) #477 ne couvre PAS les labels traduits.** Il n'enveloppe que le `segment` (numéral locale-stable `T20`/`MISS`) au band ; over-lines de section, titres de modale, noms joueurs board (`labelMedium` CAPS letterSpacing 1.2) n'ont pas ce filet — débordent.
4. **Titres de modale & snackbars longs.** `gameEndGameTitle`, `gameMenuEndDrill` (→`Oefening beëindigen`), `gameUndoLastDart` (→`Letzten Dart rückgängig machen`, ×2.14) ; snackbars `gameRoundLimitReached`/`setupCouldNotStartRetry`. Ellipse propre vs troncature en plein mot vs débordement vertical.
5. **Badges/tabs/colonnes stats.** Onglet `statsOthersTab`, `statsColAverage` (→`GEMIDDELDE` NL), en-têtes history `historyColTurn` (→`Aufnahme`), `historyTurnBreakdown` (→`Aufnahmen-Aufschlüsselung`, ×1.79).

**Heuristiques** — DE/NL +25-35% de longueur ; composés allemands = mots **non-cassables** (un conteneur fixe ne wrappe pas, il déborde) ; ALL-CAPS + letterSpacing 1.2 multiplie la largeur ; numéraux `StatFormatter` locale-stables (chasser le débordement côté **labels**, pas chiffres) ; tester aussi `textScaleFactor ≥ 1.3` (accessibilité) qui compose avec l'expansion ; 3 échecs distincts : ellipse (OK) / troncature laide ou rayures (bug) / wrap qui pousse hors écran (bug).

### 2.3 Qualité / jargon darts par langue (web-search)
**Charte exploratoire** — *Missions*
1. **Terme consensuel par langue pour chaque concept.** checkout, leg, bust, ton/180, double-out/in, marks, bull/double-bull, around the clock, shanghai, catch 40 : terme réellement utilisé par la communauté darts de la langue — ni calque inventé, ni anglicisme parasite. Trancher : (a) loanword légitime / (b) terme natif requis / (c) anglicisme à corriger.
2. **Statuer sur les chaînes « identiques à l'EN ».** Critère : mot d'UI générique (Name, Error, Round, System, Tips, « Win N games ») → à traduire en principe ; terme de jargon (Darts, 180, marks) → loanword admis possible.
3. **Cohérence intra-langue d'un terme.** « leg » rendu tantôt « manche » tantôt « leg » dans une même langue = défaut.
4. **Confirmer par recherche web l'usage réel** (glossaires/fédérations) avant de trancher — mémoire `feedback_translate_via_web_search`.

**Termes/clés à risque par langue (point de départ)**
- **de** : `commonName='Name'`, `settingsThemeSystem='System'` (ambigus EN/DE), `summaryDarts='Darts'` (loanword tech/jargon probable) ; + `leg`/Aus, `statCheckout`, `stat180s`.
- **nl** : `achievementWins10/50/100Description='Win N games'` (phrase complète → présomption bug), `rulesHeadingTips='Tips'` / `setupSectionVariant='VARIANT'` (plausibles) ; + `leg`/`checkout`/`marks`.
- **it** : `summaryRound='Round'` (vs turno/giro — vérifier cohérence), `settingsFeedbackSection` (prestito).
- **es** : `commonError='Error'` (homographe légitime) ; + `leg`/manga, `checkout`/cierre, `bust`/pasarse, `marks`/marcas, `bull`/diana.
- **fr/pt** (non flaggés) : couvrir `leg`/manche, `checkout`, `bust`/dépassé, `marks`/marques, `bull`/mouche, `180`/ton.

**Heuristiques** — anglais sur clé **non-jargon** (réglages/nav/succès) = suspect par défaut ; sur clé **jargon** = loanword plausible (vérifier glossaire) ; ne jamais inventer un calque (loanword > traduction fabriquée, mais le signaler comme décision) ; vérifier le verdict sur TOUTES les occurrences.

### 2.4 Pluriels & interpolation
**Charte exploratoire** — *Missions*
1. **Catégories ICU correctes par langue.** 9 clés à pluriel ; **fr & pt** : `count=0` doit tomber dans `one` (singulier), contrairement à en/de/nl/es — tester explicitement 0. Aucune langue du projet n'exige `few`/`many` cardinal — signaler toute catégorie surnuméraire ou `other`-seul.
2. **Accord nombre↔substantif & participe.** « 1 joueur »/« 3 joueurs », « 1 leg gagné »/« 3 legs gagnés » ; genres/participes (fr/es/it/pt : gagné/gagnés, non localisée/localisées) ; invariabilité voulue (de `Spieler`, it `round`/`leg`) vs copier-coller paresseux.
3. **Placeholders bien placés (ordre des mots).** Multi-placeholders sensibles : `gameLegWonBy`, `summaryNOfMCheckouts` (`{successes}/{attempts}` réordonné en fr/it), `gameCheckoutSuccess`, `gameLegOf`. + incohérence convention « 1 » en dur (branch `one`) vs `{count}` réinjecté.
4. **Plural inline dans une phrase.** `gameAdvanceTurnBody` : phrase fluide quelle que soit la branche, pas de double-espace ni ponctuation orpheline.

**Clés à pluriel** : `commonRelativeDaysAgo`, `summaryLegsWon`, `statsHeatmapUnlocated`, `gameAdvanceTurnBody` (inline), `gameDartsThrown`, `setupLineupCount`, `setupRoundsCount`, `setupLegsCount`, `autoScorerStatusDetected`.
**Heuristiques** — tester 0/1/2/grand nombre ; double-espaces, séparateurs `·`/`|` mal entourés, ponctuation (espagnol `¿?`, français espace insécable avant `?`).

### 2.5 Cohérence terminologique
**Charte exploratoire** — *Missions*
1. **Concept → terme unique par langue.** Indexer concept → traductions observées sur toutes les clés ; tout concept avec >1 radical distinct (hors flexion/casse) = dérive synonymique à confirmer.
2. **Cohérence inter-surfaces.** Même terme entre board (`game*`) / post-game (`summary*`) / history (`history*`) / stats (`stat*`) pour : leg, checkout, round/tour, score, average, marks, player.
3. **Étiquettes de variantes.** Mêmes mots entre picker (Title Case) / header in-game / history (minuscule) — la **casse divergente est voulue** (CLAUDE.md, ne pas signaler) ; seul un radical divergent est un défaut.
4. **Verbes d'action partagés.** start / next (Leg/Player/Round/Target) / cancel / delete : un même geste = même verbe (pas supprimer↔effacer, suivant↔prochain).

**Heuristiques** — normaliser casse/ponctuation/flexion avant comparaison (radical seul) ; comparer **intra-langue** uniquement ; emprunt EN acceptable s'il est universel dans la langue, le défaut est l'inconstance. Clusters concept→clés détaillés (leg, round, player, checkout, score/average/marks, variantes, actions) fournis par l'analyse — à recouper.

### 2.6 Lacunes de localisation côté code
**Charte exploratoire** — *Missions*
1. **Confirmer le gap Count-Up (parité avec X01).** `count_up_board_page.dart` est le **seul board non localisé** ; chaque chaîne en dur a déjà une clé ARB consommée par X01 → câblage simple, **priorité si Count-Up est expédié**.
2. **Surfaces d'erreur globales hors-feature** (`app.dart`, `app_router.dart`, `error_retry_widget.dart`) : déterminer atteignabilité avec/sans `AppLocalizations` dans l'arbre (DB-error s'affiche avant `MaterialApp` → pré-l10n acceptable mais à documenter ; `ErrorRetryWidget` « Retry » utilisé par ~10 pages prod → vrai gap).
3. **Labels non-`Text` masqués** : `semanticLabel`/`tooltip`/`hintText`/`labelText`, titres dialog, `content:` de SnackBar (accessibilité = contenu traduisible). Ex. `home_page` `semanticLabel/tooltip: 'Settings'`.
4. **Bloc auto_scorer (~33) = débogage** : won't-fix présumé, sauf chemin atteignable hors mode dev (ex. snackbar « Recording not found. »).
5. **Acronymes darts** (`PPR`/`MPR`/`MPT`, labels d'axes) : termes universels, won't-fix présumé.

**Offenders confirmés (file:line — catégorie)** : `count_up_board_page.dart` :84 `'Error'`, :92 `'Game not found'`, :133 `semanticLabel 'Game options'`, :146 `'End Game'`, :150 `'Settings'`, :279 `'Undo last dart'`, :287 `'NEXT PLAYER'/'NEXT ROUND'` → **(a) gaps réels, clés existantes** ; `error_retry_widget.dart:35,54` `'Retry'` (~10 pages) → **(a)** ; `home_page.dart:24,25` `'Settings'` → **(a)** ; `app.dart:38` `'Database failed to open: $e'` → **(b)** pré-l10n, documenter ; `app_router.dart:134,135` `'Error'`/`'Page not found'` → **(a/b)** ; `auto_scorer/**` ~33 → **(b)** débogage ; `ppr_trend_chart_widget.dart:196` `'PPR'` → **(c)** acronyme.

**Heuristiques** — test décisif vrai-gap vs débogage : la chaîne a-t-elle un jumeau déjà localisé ? ; exclure `*.g.dart`/`*.freezed.dart`/`gen/` ; exceptions `repository_exception.dart` = messages dev (Sentry, pas affichés) ; chaîne en `domain/`/`data/` ≠ user-facing.

---

## 3. Sortie

- Findings i18n → carnet `docs/testing/findings-2026-06.md` (format plan §8). Candidats déjà nets :
  Count-Up non localisé (a), `ErrorRetryWidget` « Retry » (a), `home_page` Settings (a).
- Passe 2 : boucle sur les 7 locales (screenshots écrans à fort texte : setup, post-game, stats, settings) +
  parcours nominal complet en **DE** (mots longs) ; vérification jargon par recherche web.
