# Bob's 27 — règles canoniques (oracle de test)

> **Statut : ORACLE.** Source de vérité pour la vérification de correctness (axe 1). Bob's 27
> n'avait pas de table de transitions ; ce document capture les **règles canoniques** (routine
> de Bob Anderson) à partir de sources externes, pour servir d'oracle indépendant de l'engine.
> Sources : godartspro.com/app/bobs-27, dartsplanet.tv, darthelp.com (juin 2026).
>
> ⚠️ **Ce doc décrit le jeu canonique, PAS forcément l'implémentation actuelle.** Voir §7
> « Divergences avec l'implémentation » — à trancher avec le mainteneur, à ne pas figer.

---

## 1. Vue d'ensemble

Routine d'entraînement aux doubles inventée par Bob Anderson. Score de départ **27**. Le joueur
parcourt **tous les doubles dans l'ordre, de D1 à D20, puis termine sur le Bull (Double Bull)** —
soit **21 cibles**. À chaque cible, 3 fléchettes. On gagne des points en touchant le double de la
manche et on en perd quand on rate les trois.

## 2. Setup

| Paramètre | Valeur |
|---|---|
| Score de départ | 27 |
| Séquence de cibles | D1, D2, …, D20, **Bull (DB)** (21 manches) |
| Fléchettes par manche | 3 |
| Joueurs | solo à l'origine ; jouable en multi (chacun sa progression) |

## 3. Cibles par manche

- Manche `n` (1..20) → cible = `D{n}`.
- Manche **21** → cible = **Double Bull** (`DB`).

## 4. Scoring

| Événement | Effet sur le score |
|---|---|
| Chaque fléchette dans la cible (manche n ≤ 20) | `+ 2 × n` |
| Chaque Double Bull touché (manche 21) | `+ 50` |
| Aucune des 3 fléchettes ne touche la cible | `− 2 × n` (et `− 50` en manche bull) |
| Single / triple / autre segment | aucun effet (seul le double exact de la manche compte) |

## 5. Fin de partie

- La partie se termine après la **manche 21 (bull)**.
- Condition de fin anticipée : si le score tombe **à zéro ou en dessous**, la partie s'arrête.
- Résultat = score final. Pas d'adversaire à battre en solo.

## 6. Score parfait

`27 + Σ_{n=1..20}(3 × 2n) + (3 × 50)` = `27 + 1260 + 150` = **1437**.
(Le 1437 documenté implique mathématiquement la manche bull : sans elle, le max est **1287**.)

## 7. Divergences avec l'implémentation actuelle (à trancher — NE PAS figer)

> Candidats findings pour l'axe 1. Décision mainteneur requise avant toute correction.

- **D-1 (P1, manche bull manquante)** — `stateless_bobs_27_engine.dart:123` termine à `roundNum >= 20`
  (cible toujours `D{roundNum}`, aucune manche bull). Max atteignable = **1287**, donc le « 1437 »
  affiché dans les règles in-app (`rulesBobs27WinningBody`, 7 langues) est **inatteignable**.
  → Soit ajouter la manche bull (aligner sur le canonique), soit corriger le texte à 1287 (variante
  20-manches assumée). **Décision mainteneur.**
- **D-2 (P2, texte de règles)** — `rulesBobs27HowB2` dit « There are 20 rounds … up to double 20 »
  (omet le bull), tout en citant 1437 dans `rulesBobs27WinningBody` → contradiction interne, à
  résoudre en même temps que D-1.
- **D-3 (note)** — fin sur `score <= 0` (zéro inclus) sans flag « busted/perdu » explicite ;
  cohérent avec « zero or below » du canonique. À confirmer côté UX (axe 2) que l'utilisateur
  comprend la fin.

## 8. Heuristiques de test (engine vs CE doc)

- Vérifier la cible de chaque manche contre §3 (dont la manche 21 = bull, **attendu canonique**).
- Recalculer le delta de score à la main (§4) et comparer ; sonder un blanchissage (`−2n`).
- Sonder explicitement l'existence (ou non) de la manche bull → c'est le test qui révèle D-1.
- Bornes de fin : score passant à 0 vs sous 0 ; fin après la dernière manche.
