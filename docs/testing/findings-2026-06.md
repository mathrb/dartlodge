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
| F-001 | Correctness | P1 | Bob's 27 — score parfait 1437 inatteignable (manche bull absente) | issue #588 |
| F-002 | Design | P2 | Surface DB-error = string brut non stylé | à confirmer |
| F-003 | Design | P2 | Incohérence empty-state (spacing 8 vs 16, titre body vs titleLarge) | infirmé (marginal, won't-fix) |
| F-004 | Design | P2 | Loading non uniforme (skeleton Players vs spinner History/Stats) | à confirmer |
| F-005 | Design | P2 | Heatmap sans légende/échelle (gap oracle DESIGN_SYSTEM §7.6) | à confirmer |
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
- Statut : **issue #588**

---

## Axe 2 — UX / flux

### F-009 — Page Statistiques : header logo au lieu d'un titre d'écran
- Axe : Design / UX (cohérence inter-écrans)
- Surface : Statistics (root / player-picker)
- Rail : web
- Sévérité : P2 (confidence basse — possiblement intentionnel)
- Observé : la page Stats affiche le logo « DARTLODGE » en header, alors que Players et History affichent un header **titré** (« Players » / « History »).
- Attendu : cohérence de traitement des headers — OU confirmer que le logo est intentionnel pour la page « hub » Stats.
- Preuve : `exec-03-stats-empty.png` (header DARTLODGE) vs `exec-01-players-empty.png` / `exec-02-history-empty.png` (titrés).
- Statut : à trier

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
- Preuve : capture de la validation résolution (DB stale) ; `lib/app/app.dart:~38`.
- Statut : à confirmer

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
- Preuve : `heatmap_dartboard_widget.dart` ; DESIGN_SYSTEM §7.6.
- Statut : à confirmer

---

## Axe 4 — Données / persistance

_(aucun finding confirmé — passe d'exécution à venir)_

---

## Axe 5 — i18n

> Candidats **pressentis** (analyse code passe 1, tableau d'offenders) — à confirmer en passe 2.

### F-006 — Count-Up board non localisé
- Axe : i18n
- Surface : Count Up board (`count_up_board_page.dart`)
- Rail : web
- Sévérité : P2
- Observé : seul board avec des chaînes en dur (« Error », « Game not found », « End Game », « Settings », « Undo last dart », « NEXT PLAYER »/« NEXT ROUND », semanticLabels) ; X01/Cricket/Practice sont localisés.
- Attendu : câbler `l10n.*` — les clés ARB existent déjà et sont consommées par X01 (`gameNotFound`, `commonError`, `gameMenuEndGame`, `settingsTitle`, `gameOptionsSemantic`, `gameUndoLastDart`, `gameNextPlayer`/`gameNextRound`). Aucune clé à créer.
- Preuve : `count_up_board_page.dart:84,92,133,146,150,279,287`.
- Statut : à confirmer (priorité si Count-Up est expédié)

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
