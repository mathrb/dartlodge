# Axe 3 — Design visuel — plan de test détaillé

> **Statut : passe 1 (checklists par dimension).** L'axe 3 est fondamentalement *visuel* :
> la passe 1 produit les **checklists de conformité** + la **galerie de surfaces à capturer** ;
> la **passe 2** (différée) capture chaque surface en Pixel 6a portrait et inspecte contre les checklists.
> Parent : `docs/plans/2026-06-19-1.0-verification-plan.md` §5. Mécanique d'exécution : voir
> `axis-1-correctness.md` §2 (rails, viewport Pixel 6a 412×915, gotchas semantics).

---

## 1. Objet & oracles

Vérifier que chaque écran respecte le système de design et que l'ensemble est cohérent.
**Méthode = screenshot + inspection œil contre tokens** (pas d'assert DOM).

- Oracle : `docs/design/DESIGN_SYSTEM.md` (réaligné #585) + `lib/core/utils/{app_colors,app_text_styles,app_spacing}.dart` + `lib/core/theme/app_theme.dart`.
- Rail : `[web]` pour conformité tokens + cohérence (Pixel 6a portrait, clair ET sombre) ; `[device]` pour la lisibilité physique réelle à distance (#477) — non reproductible en web (DPR 1).

---

## 2. Dimensions

### 2.1 Tokens couleur
**Checklist de conformité**
- [ ] Score actif = `onSurface` ; inactif/adversaire = `onSurfaceVariant` (+ carte inactive `Opacity(0.7)`) ; cible practice = `primary`.
- [ ] Over-line `label-sm` au-dessus d'un héro = `primaryFixed` (`#00FFAB`), pas `onSurfaceVariant`.
- [ ] `primary` adaptatif au thème (clair `#006D45` / sombre `#AFFFD1`) ; `primaryFixed` néon constant inter-thème ; texte sur fill néon = `onPrimaryFixed`.
- [ ] Nom joueur board : actif `primaryFixed`, inactif `onSurfaceVariant`.
- [ ] Bannière win = `win`→`primary` ; bust = `errorContainer`/`onErrorContainer` + flash `error`.
- [ ] `award`/`success` brightness-aware (via `AppTheme.award/success(context)`) — s'éclaircissent en sombre.
- [ ] Palette identité avatar : 8 hues fixes, stable par joueur, initiale `onAvatar` ; même joueur = même couleur partout.
- [ ] Boutons segment par tier (Singles `surfaceContainerHighest`/`onSurface` ; Doubles/Triples `onSurfaceVariant` + points `primaryFixed`@70% ; Bull 50 fond `primaryFixed`).
- [ ] Aucun littéral couleur hors palette §2 dans les widgets.
- [ ] Exceptions won't-fix (NE PAS signaler) : couleurs domaine dartboard/heatmap (§7.6, #195) ; ~41 alpha literals component-local (§5).

### 2.2 Typographie
**Checklist de conformité**
- [ ] Deux familles seulement (Space Grotesk scores/display/labels ; Inter body/boutons) ; pas de mélange dans un élément.
- [ ] Titres d'écran `headline-md` ALL CAPS ; tailles ≥ 11px.
- [ ] Noms joueurs board = `labelMedium` ALL CAPS `letterSpacing 1.2` (≠ `player-name` du roster, Inter 16px).
- [ ] Token de score selon nb joueurs (1j `scoreActive` 80 / 2j `scoreLarge` 64 / 3-4j `scoreMedium` 48 / 5+ `scoreSmall` 36 ; inactif décalé).
- [ ] Scores jamais tronqués/wrappés ; **aucun `FittedBox(scaleDown)` sur un score** (conteneur contraint).
- [ ] Exception camera-first : `FittedBox(scaleDown)` toléré uniquement sur les LABELS de segment.
- [ ] Boutons segment `segmentButton` (Inter SemiBold 18) ; multiplicateur `multiplierLabel` (Inter Medium 11).
- [ ] Nombres via `StatFormatter` (pas de zéros décimaux superflus → trahit un `toStringAsFixed` inline).

### 2.3 Espacements / layout
**Checklist de conformité**
- [ ] Marge horizontale de page = `space4` (16dp) partout ; grid 4dp (aucun 5/7/10/14/18 hors tokens documentés).
- [ ] Rayons : cartes `radiusLarge` 16 ; CTA/chip config `radiusMedium` 12 ; cellules strip/segment/badge `radiusSmall` 8 ; modales/segmented `radiusXLarge` 24 ; pills `radiusFull`.
- [ ] No-Line Rule : espacement (`space6/8/10`) à la place des dividers 1px (seule ligne tolérée = bord bas status bar `outlineVariant`@10%).
- [ ] Touch-target grille segments ≥ 48dp.
- [ ] Padding bas scrollable = `space16` (64dp) au-dessus de la nav bar ; SafeArea haut/bas (encoche/gesture Pixel 6a).
- [ ] **Aucun overflow/clipping à 412×915** (pas de bandeau jaune-noir, pas d'ellipsis non voulue, pas de carte tronquée).
- [ ] Carte active : accent gauche 4dp + ombre (`opacityActiveCardShadow` 0.50) ; inactive sans ombre.
- [ ] Strips (X01/Cricket/Practice) alignés entre eux (padding 16h/4v, gap 8dp).

### 2.4 Camera-first / at-distance (#477)
> Web : `CameraPreview` stubbé, mais le **chrome** est rendu via `dartlodgeSim.enableAutoScoring()`. Lisibilité physique réelle = **device-only**.

**Checklist de conformité**
- [ ] Band proéminente : slots ~110px, numéraux `scoreMedium` (48px) `primaryFixed` ; label long (`MISS`) en `FittedBox(scaleDown)` sans wrap ; numéraux courts non gonflés.
- [ ] Slot lancé = fill `primaryFixed`@10% + ghost border@20% `radiusMedium` ; slot vide = `surfaceContainer` + `more_horiz` (ou `add_circle_outline` si saisie manuelle activée).
- [ ] Hero : `scoreActive` 80px `onSurface`, 1 ligne, jamais scalé ; over-line `labelSmall` `primaryFixed` au-dessus.
- [ ] Strips secondaires subordonnés au héro (~1.5× compact, ne contestent pas la valeur).
- [ ] Cricket : `CricketMarkPainter` traits ~4px (slash/cross/circled-cross), 3+ `primaryFixed`, dead targets atténués ; colonnes flex sans scroll horizontal (2-4 joueurs).
- [ ] Vignette caméra compacte (~96px) + control bar dessous ; `GameStatusBarWidget(showDarts:false)` (darts seulement dans la band, pas dupliqués).
- [ ] Composition identique X01/Cricket/Practice (pas de drift de taille par jeu).
- **Device-only** : lisibilité à ~2,4 m, resize vignette↔expanded, preview live.

### 2.5 Cohérence inter-écrans
**Checklist de conformité**
- [ ] Carte résumé de partie identique liste History ↔ détail/post-game (`radiusLarge`, typo, couleurs gagnant/perdant).
- [ ] Badge AVG (dart-badge `primaryFixed`@10% / border@20% / `radiusSmall`) identique partout (picker, roster, cartes).
- [ ] `kineticCardDecoration` identique (gradient 135°, ghost border@10%, `radiusLarge`) sur cartes Home & setup ; splash `kineticSplashColor` (pas de scale "pop").
- [ ] `AppHeader` (logo/back/action) positionné/stylé identiquement sur Home/History/Stats/Players/Settings.
- [ ] Onglets stats, nav rows, grille segments cohérents inter-écrans.
- [ ] Parité thème Light/System/Dark (sélecteur 3-voies) : chaque écran lisible/cohérent dans les deux ; néon `primaryFixed` constant, `primary` adaptatif.
- [ ] Empty-states cohérents (typo message, iconographie, placement).
- [ ] Labels de variante : Title Case picker/header vs lowercase History = **intentionnel** (CLAUDE.md), ne pas signaler.

### 2.6 Heatmap
**Checklist de conformité**
- [ ] Colormap froid→chaud (transparent→bleu→cyan→jaune→rouge), dense=rouge, intuitif sans inversion ; alpha croît avec densité (pas d'auréole opaque).
- [ ] Rendu KDE lisse (gaussien + `FilterQuality.medium`), pas blocky malgré grille 64×64 ; densité rognée au disque (clipPath rond).
- [ ] Plateau auto-dessiné correct (20 segments noir/crème alternés, anneaux double/triple vert/rouge, bull simple+double, 20 en haut) ; carré (AspectRatio 1, maxWidth 320) sans déformation.
- [ ] Couleurs plateau = littéraux domaine (#195), pas tokens — ne pas signaler.
- [ ] Titre section `labelSmall` CAPS `letterSpacing 1.2` (`primaryFixed` all-time / `onSurfaceVariant` post-game).
- [ ] Post-game multi-joueurs : sélecteur `SegmentedButton` par compétiteur ; note « N fléchettes non localisées » si mixte.
- [ ] Section auto-masquée (`SizedBox.shrink`) si aucune position localisée — pas de plateau vide/flash.
- [ ] All-time : un plateau par onglet gameType, ignore visiblement le `TimeRangeSelector`.
- [ ] ⚠️ **À confirmer (gap oracle)** : absence de numéros de segments et de légende/échelle de couleur (DESIGN_SYSTEM dit « légende lisible » — le widget n'en dessine pas).

### 2.7 États transitoires / vides (visuel)
> Le *look* des états (le *comportement* est en axe 2 §3.2).

**Checklist de conformité**
- [ ] Empty-states : icône outline 64px `onSurfaceVariant` cohérente (Players/History/Stats) ; titre même token ; rythme icône→label uniforme ; centré.
- [ ] Loading cohérent : `CircularProgressIndicator` `primary` centré ; skeleton qui épouse la forme finale (fill `surfaceContainerHighest`, pas gris codé en dur).
- [ ] Pas de flash/layout-jump au load→data (le placeholder occupe la région finale).
- [ ] Erreurs via `ErrorRetryWidget` (icône + titre + message borné + retry), pas un dump rouge brut.
- [ ] Press feedback : ripple `kineticSplashColor` + kinetic shift vers `primaryFixedDim` (§10.1), pas de "pop".

---

## 3. Galerie de surfaces à capturer (passe 2)

> Capturer chaque surface en Pixel 6a portrait, **clair ET sombre**. Liste dérivée des dimensions.

- **Home** (cartes kinetic + nav rows) · **Setup** (variant, player selection, lineup, config sheet)
- **Boards manuels** : X01 (1/2/3-4/5+ joueurs), Cricket, Count Up, Practice (ATC/Catch40/Bob's27/Checkout)
- **Boards camera-first** (via sim `enableAutoScoring`) : X01, Cricket, Practice
- **Post-game summary** (+ bannière win, heatmap per-player, sélecteur multi-joueurs)
- **History** (liste, game detail) · **Stats** (tab, player stats, heatmap all-time, badges AVG)
- **Players** (liste, detail, create, edit) · **Achievements** · **Settings** (thème 3-voies, sections)
- **États non-heureux** : Players/History/Stats vides ; un loading/skeleton ; surface DB-error
- **Snackbar/flash bust** ; modals (leg/win) ; toast succès

## 4. Findings pressentis (à confirmer visuellement en passe 2)

> Repérés par l'analyse code des agents passe 1 — **hypothèses**, à valider sur screenshot avant toute issue.

- **F? (P2)** — Surface DB-error (`app.dart` branche `error:`) = `Center(child: Text('Database failed to open: $e'))` : string brut, sans icône/thème/localisation/retry (vu sur device pendant la validation résolution). Candidat finding design + UX.
- **F? (P2)** — Libellés en dur non localisés : `'Retry'` (`ErrorRetryWidget`), `'Page not found'`/`'Error'` (router `_errorPage`).
- **F? (P2)** — Incohérence empty-state : gap icône→label 16dp (Players/Stats) vs 8dp (History) ; History titre en body vs `titleLarge` ailleurs.
- **F? (P2)** — Loading non uniforme : Players a un skeleton façonné, History/Stats un simple spinner.
- **F? (P2, gap oracle)** — Heatmap sans légende/échelle ni numéros de segments, alors que DESIGN_SYSTEM §7.6 mentionne une « légende lisible ». Trancher : ajouter la légende OU corriger l'oracle.

## 5. Passe 2 (capture + inspection)

_[à exécuter : app lancée en Pixel 6a portrait, sim bridge pour camera-first/heatmap ; capturer la galerie §3 ; cocher les checklists §2 ; confirmer/infirmer les findings §4.]_

## 6. Sortie

- Findings design confirmés → carnet `docs/testing/findings-2026-06.md` (format plan §8).
- Régressions visuelles éventuelles → baseline de screenshots (optionnel post-1.0).
