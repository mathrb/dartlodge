# Axis 5 — i18n — detailed test plan

> **Status: pass 1 (exploratory charters per concern).** Handled **last** (UI stabilized
> by axes 1-4). Scripted cases / per-locale review = pass 2 (deferred).
> Part of the pre-1.0 verification cycle (2026-06). Mechanics: see `axis-1-correctness.md` §2
> (Pixel 6a viewport 412×915) + language switch via `localeSettingProvider`.

---

## 1. Purpose & oracles

Verify that the app is correct and polished in all **7 languages** (en/fr/de/es/it/nl/pt).
**Key parity has already been audited and is perfect** (515 keys × 7, 0 missing/orphaned,
placeholders intact — see `doc-drift-audit-2026-06-19.md`) → axis 5 targets what parity does NOT cover.

- Oracles: `lib/l10n/arb/*.arb` (template `app_en.arb`), `lib/l10n/l10n.yaml` + `gen_l10n`,
  `lib/l10n/gen/app_localizations*.dart`, `test/l10n/arb_integrity_test.dart` (ARB↔ARB parity gate).
- Rail: `[web]` (language switch + screenshots of the 7 locales); `[device]` marginal.

---

## 2. Concerns

### 2.1 Missing keys / fallback at render time
**Exploratory charter** — *Missions*
1. **No raw key on screen.** The real risk ≠ ARB (perfect parity) but **snapshot-key ↔ label confusion**: projection keys (`x01_average`, `cricket.mpt`, variant slugs, `GameType.name`) are used as the argument of a mapping; an `orElse: () => key` would display the identifier. Target post-game, stats, heatmap, achievements.
2. **Every consumed key exists in the ARB template.** The `arb_integrity_test` gate compares ARB↔ARB, **not** code→ARB. `nullable-getter: false` → a missing getter breaks compilation of `gen/` (so regenerate + commit `gen/` in lock-step — CI doesn't run build_runner).
3. **Runtime language switch re-renders the whole tree.** Changing the language from Settings must propagate to every mounted screen (board, bust/leg modals, `AchievementNotificationHost`, snackbars, sheets); a label captured in `initState`/a field stays frozen. `_BootstrapApp` (pre-DB) has no `Localizations` — no localizable text goes through it.
4. **System locale resolution + fallback.** `resolveAppLocale` matches on `languageCode` only, falls back to `en`; device in an unlisted language (`ja`) → clean `en`; regional variants (`pt_BR`, `de_CH`) → base language; invalid stored code → graceful. Consistent cardinality: `kSupportedLocales` ↔ generated `supportedLocales` ↔ 7 ARBs ↔ 7 `gen/` ↔ `kLanguageAutonyms`.

**Heuristics** — gen_l10n falls back to the template *silently* (perfect parity hides this risk for a *future* key); `orElse: () => key` = anti-pattern to flush out; a label read outside `build` (field/`late final`) doesn't follow the switch; a missing autonym breaks the selector without an error.

### 2.2 Text overflow (Pixel 6a portrait 412×915)
**Exploratory charter** — *Missions*
1. **Burst the config chips in DE/NL.** `_MetadataRow` (variant selection): `setupChipIn/Out/Legs` chips in a fixed-spacing `Row`, **with no `Flexible`/`maxLines`/overflow**. DE: `IN`→`EINSTIEG` (×2.67), `OUT`→`AUSSTIEG` → does the X01 row (4 chips) overflow (stripes) at 412px?
2. **ALL-CAPS CTAs with high letterSpacing.** `setupStartGame` (→`SPIEL STARTEN`), `gameNextRound` (→`NÄCHSTE RUNDE`), `gameNextPlayer` (→`NÄCHSTER SPIELER`), `setupApply` (→`ANWENDEN`): the 1.0-1.2 letterSpacing amplifies the width — no truncation or wrap that breaks the bar height.
3. **The #477 FittedBox(scaleDown) does NOT cover translated labels.** It only wraps the `segment` (locale-stable numeral `T20`/`MISS`) in the band; section over-lines, modal titles, board player names (`labelMedium` CAPS letterSpacing 1.2) don't have that safety net — they overflow.
4. **Long modal titles & snackbars.** `gameEndGameTitle`, `gameMenuEndDrill` (→`Oefening beëindigen`), `gameUndoLastDart` (→`Letzten Dart rückgängig machen`, ×2.14); snackbars `gameRoundLimitReached`/`setupCouldNotStartRetry`. Clean ellipsis vs mid-word truncation vs vertical overflow.
5. **Stats badges/tabs/columns.** `statsOthersTab` tab, `statsColAverage` (→`GEMIDDELDE` NL), history headers `historyColTurn` (→`Aufnahme`), `historyTurnBreakdown` (→`Aufnahmen-Aufschlüsselung`, ×1.79).

**Heuristics** — DE/NL +25-35% length; German compounds = **unbreakable** words (a fixed container doesn't wrap, it overflows); ALL-CAPS + letterSpacing 1.2 multiplies the width; `StatFormatter` numerals are locale-stable (hunt overflow on the **labels**, not the digits); also test `textScaleFactor ≥ 1.3` (accessibility), which compounds with the expansion; 3 distinct failure modes: ellipsis (OK) / ugly truncation or stripes (bug) / wrap that pushes off screen (bug).

### 2.3 Quality / darts jargon per language (web search)
**Exploratory charter** — *Missions*
1. **Consensus term per language for each concept.** checkout, leg, bust, ton/180, double-out/in, marks, bull/double-bull, around the clock, shanghai, catch 40: the term actually used by that language's darts community — neither an invented calque nor a stray anglicism. Decide: (a) legitimate loanword / (b) native term required / (c) anglicism to fix.
2. **Rule on the strings "identical to EN".** Criterion: generic UI word (Name, Error, Round, System, Tips, "Win N games") → should in principle be translated; jargon term (Darts, 180, marks) → loanword possibly acceptable.
3. **Intra-language consistency of a term.** "leg" rendered sometimes "manche", sometimes "leg" in the same language = defect.
4. **Confirm real usage by web search** (glossaries/federations) before deciding — memory `feedback_translate_via_web_search`.

**At-risk terms/keys per language (starting point)**
- **de**: `commonName='Name'`, `settingsThemeSystem='System'` (ambiguous EN/DE), `summaryDarts='Darts'` (probable tech/jargon loanword); + `leg`/Aus, `statCheckout`, `stat180s`.
- **nl**: `achievementWins10/50/100Description='Win N games'` (full sentence → presumed bug), `rulesHeadingTips='Tips'` / `setupSectionVariant='VARIANT'` (plausible); + `leg`/`checkout`/`marks`.
- **it**: `summaryRound='Round'` (vs turno/giro — check consistency), `settingsFeedbackSection` (loanword).
- **es**: `commonError='Error'` (legitimate homograph); + `leg`/manga, `checkout`/cierre, `bust`/pasarse, `marks`/marcas, `bull`/diana.
- **fr/pt** (not flagged): cover `leg`/manche, `checkout`, `bust`/dépassé, `marks`/marques, `bull`/mouche, `180`/ton.

**Heuristics** — English on a **non-jargon** key (settings/nav/achievements) = suspect by default; on a **jargon** key = plausible loanword (check a glossary); never invent a calque (loanword > made-up translation, but flag it as a decision); check the verdict on ALL occurrences.

### 2.4 Plurals & interpolation
**Exploratory charter** — *Missions*
1. **Correct ICU categories per language.** 9 plural keys; **fr & pt**: `count=0` must fall into `one` (singular), unlike en/de/nl/es — test 0 explicitly. No project language requires cardinal `few`/`many` — report any superfluous category or `other`-only.
2. **Number↔noun & participle agreement.** "1 joueur"/"3 joueurs", "1 leg gagné"/"3 legs gagnés"; genders/participles (fr/es/it/pt: gagné/gagnés, non localisée/localisées); intended invariability (de `Spieler`, it `round`/`leg`) vs lazy copy-paste.
3. **Placeholders in the right place (word order).** Sensitive multi-placeholder keys: `gameLegWonBy`, `summaryNOfMCheckouts` (`{successes}/{attempts}` reordered in fr/it), `gameCheckoutSuccess`, `gameLegOf`. + inconsistent convention of a hardcoded "1" (`one` branch) vs re-injected `{count}`.
4. **Inline plural within a sentence.** `gameAdvanceTurnBody`: fluent sentence whatever the branch, no double space or orphan punctuation.

**Plural keys**: `commonRelativeDaysAgo`, `summaryLegsWon`, `statsHeatmapUnlocated`, `gameAdvanceTurnBody` (inline), `gameDartsThrown`, `setupLineupCount`, `setupRoundsCount`, `setupLegsCount`, `autoScorerStatusDetected`.
**Heuristics** — test 0/1/2/a large number; double spaces, badly spaced `·`/`|` separators, punctuation (Spanish `¿?`, French non-breaking space before `?`).

### 2.5 Terminology consistency
**Exploratory charter** — *Missions*
1. **Concept → single term per language.** Index concept → observed translations across all keys; any concept with >1 distinct stem (ignoring inflection/case) = synonym drift to confirm.
2. **Cross-surface consistency.** Same term across board (`game*`) / post-game (`summary*`) / history (`history*`) / stats (`stat*`) for: leg, checkout, round/turn, score, average, marks, player.
3. **Variant labels.** Same words across picker (Title Case) / in-game header / history (lowercase) — the **diverging case is intended** (CLAUDE.md, don't report); only a diverging stem is a defect.
4. **Shared action verbs.** start / next (Leg/Player/Round/Target) / cancel / delete: one gesture = one verb (not supprimer↔effacer, suivant↔prochain).

**Heuristics** — normalize case/punctuation/inflection before comparing (stem only); compare **within a language** only; an EN loanword is acceptable if it's universal in the language, the defect is inconsistency. Detailed concept→key clusters (leg, round, player, checkout, score/average/marks, variants, actions) provided by the analysis — to cross-check.

### 2.6 Localization gaps in the code
**Exploratory charter** — *Missions*
1. **Confirm the Count-Up gap (parity with X01).** `count_up_board_page.dart` is the **only non-localized board**; every hardcoded string already has an ARB key consumed by X01 → simple wiring, **priority if Count-Up ships**.
2. **Global out-of-feature error surfaces** (`app.dart`, `app_router.dart`, `error_retry_widget.dart`): determine reachability with/without `AppLocalizations` in the tree (DB-error shows before `MaterialApp` → pre-l10n acceptable but to be documented; `ErrorRetryWidget` "Retry" used by ~10 prod pages → real gap).
3. **Hidden non-`Text` labels**: `semanticLabel`/`tooltip`/`hintText`/`labelText`, dialog titles, SnackBar `content:` (accessibility = translatable content). E.g. `home_page` `semanticLabel/tooltip: 'Settings'`.
4. **auto_scorer block (~33) = debugging**: presumed won't-fix, unless a path is reachable outside dev mode (e.g. the "Recording not found." snackbar).
5. **Darts acronyms** (`PPR`/`MPR`/`MPT`, axis labels): universal terms, presumed won't-fix.

**Confirmed offenders (file:line — category)**: `count_up_board_page.dart` :84 `'Error'`, :92 `'Game not found'`, :133 `semanticLabel 'Game options'`, :146 `'End Game'`, :150 `'Settings'`, :279 `'Undo last dart'`, :287 `'NEXT PLAYER'/'NEXT ROUND'` → **(a) real gaps, existing keys**; `error_retry_widget.dart:35,54` `'Retry'` (~10 pages) → **(a)**; `home_page.dart:24,25` `'Settings'` → **(a)**; `app.dart:38` `'Database failed to open: $e'` → **(b)** pre-l10n, document; `app_router.dart:134,135` `'Error'`/`'Page not found'` → **(a/b)**; `auto_scorer/**` ~33 → **(b)** debugging; `ppr_trend_chart_widget.dart:196` `'PPR'` → **(c)** acronym.

**Heuristics** — the decisive test for real gap vs debugging: does the string have an already-localized twin?; exclude `*.g.dart`/`*.freezed.dart`/`gen/`; `repository_exception.dart` exceptions = dev messages (Sentry, not displayed); a string in `domain/`/`data/` ≠ user-facing.

---

## 3. Output

- i18n findings → log `docs/testing/findings-2026-06.md` (see its Convention section). Candidates already clear:
  Count-Up not localized (a), `ErrorRetryWidget` "Retry" (a), `home_page` Settings (a).
- Pass 2: loop over the 7 locales (screenshots of text-heavy screens: setup, post-game, stats, settings) +
  full nominal journey in **DE** (long words); jargon verification by web search.
