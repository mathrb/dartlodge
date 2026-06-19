# Shanghai — règles canoniques (oracle de test)

> **Statut : ORACLE.** Source de vérité pour l'axe 1. Shanghai n'avait pas de table de
> transitions ; ce document capture les **règles canoniques** du jeu pour servir d'oracle
> indépendant de l'engine.
> Sources : groupgames101.com, gldproducts.com, darthelp.com, mostdartgames.com (juin 2026).
>
> ⚠️ Voir §7 « Divergences avec l'implémentation » — à trancher, à ne pas figer.

---

## 1. Vue d'ensemble

Jeu **multi-joueurs** (compétitif). Chaque manche cible un numéro précis, en montant à partir de 1.
Seules les touches sur le numéro de la manche comptent. On gagne soit au **plus haut score** en
fin de partie, soit par une **victoire instantanée « Shanghai »**.

## 2. Setup

| Paramètre | Valeur |
|---|---|
| Joueurs | 2+ (compétitif ; « unlimited ») |
| Manches | numéros 1 → N, dans l'ordre (N variable ; souvent 7 ou 20) |
| Fléchettes par tour | 3 |

## 3. Cibles par manche

- Manche `n` → cible = le numéro `n` (manche 1 → 1, …). Seul ce numéro score ce tour-là.

## 4. Scoring (par fléchette sur le numéro de la manche)

| Touche | Points |
|---|---|
| Simple `n` | `n × 1` |
| Double `n` | `n × 2` |
| Triple `n` | `n × 3` |
| Hors numéro / Bull / Miss | 0 |

> Note de source : une page (groupgames101) résume « single=1, double=2, triple=3 » — c'est le
> **multiplicateur**, pas le score. Le scoring canonique dominant (et le plus répandu) est
> **numéro × multiplicateur** (triple-7 en manche 7 = 21). C'est cette convention qui fait foi ici.

## 5. Conditions de victoire

1. **Plus haut score** à la fin de la dernière manche.
2. **Shanghai (victoire instantanée)** — toucher, **dans le même tour**, un **simple + un double +
   un triple** du numéro de la manche (dans n'importe quel ordre) → fin immédiate, ce joueur gagne.

**Départage (égalité de score)** : compter les triples ; si toujours à égalité, « bull up » ou tous
gagnants (selon variante).

## 6. Cas-limites

- Un Shanghai n'est possible qu'à la 3ᵉ fléchette d'un tour (il faut les 3 types).
- 3 touches du numéro sans couvrir les 3 multiplicateurs (ex. 3 simples) ≠ Shanghai.
- Aucune fléchette acceptée après une victoire (Shanghai ou fin de partie).

## 7. Divergences avec l'implémentation actuelle (à trancher — NE PAS figer)

> Candidats findings pour l'axe 1. `stateless_shanghai_engine.dart`, défaut `shanghaiTotalRounds = 7`.

- **D-1 (P2, texte de règles trompeur)** — `rulesShanghaiWinningBody` / `…ObjectiveBody` décrivent
  Shanghai comme un drill **« solo … no opponent to beat »**. Le canonique est **multi-joueurs
  compétitif**, et l'engine SUPPORTE le multi-joueurs (victoire = plus haut score / Shanghai
  instantané). → Le **texte de règles** diverge du canonique et de l'engine ; l'engine, lui, est
  conforme. Corriger le texte (axe 2 / i18n), pas l'engine.
- **D-2 (P2, départage)** — l'engine départage par **« premier de la liste »** ; le canonique
  départage par **nombre de triples** (puis bull-up / nul). Divergence de tie-break → finding ou
  simplification assumée. **Décision mainteneur.**
- **D-3 (note)** — N de manches **configurable** (défaut 7) : choix de design légitime (le canonique
  admet 7 ou 20). Pas un bug ; à confirmer comme intentionnel.
- **D-4 (note)** — l'engine enregistre aussi un Shanghai comme `practiceSuccesses++` (sémantique
  hybride drill/match). À clarifier si Shanghai est positionné comme jeu compétitif ou drill.

## 8. Heuristiques de test (engine vs CE doc)

- Score par fléchette = `numéro_manche × multiplicateur`, **uniquement** sur le numéro de la manche.
- Shanghai = {simple, double, triple} du numéro dans le même tour, ordre indifférent ; évalué à la
  3ᵉ fléchette ; faux-positif = 3 touches sans les 3 types.
- Plus haut score en fin de partie ; sonder le **départage** (révèle D-2).
- Multi-joueurs vs « solo » du texte (révèle D-1).
- Bull et Miss non-scorants ; aucune fléchette après victoire.
