# Catch 40 — règles canoniques (oracle de test)

> **Statut : ORACLE.** Source de vérité pour l'axe 1. Catch 40 n'avait pas de table de
> transitions ; ce document capture les **règles canoniques** du jeu (origine : GoDartsPro)
> pour servir d'oracle indépendant de l'engine.
> Sources : godartspro.com/catch-40, dartcounterapp.com, dolfdarts.com (juin 2026).

---

## 1. Vue d'ensemble

Drill de finition **solo**. Le joueur enchaîne **40 checkouts**, de **61 à 100**, et marque des
points selon la rapidité de chaque finition. But : finir chaque score en un minimum de fléchettes.

## 2. Setup

| Paramètre | Valeur |
|---|---|
| Cibles (outs) | 61, 62, …, 100 (40 cibles) |
| Fléchettes par cible | jusqu'à 6 |
| Finition | sur un double (checkout = score à exactement 0 sur un double) |
| Joueurs | solo (pas d'adversaire) |

## 3. Progression

- Démarre à l'out **61**, puis 62, …, jusqu'à **100**.
- Pour chaque out : jusqu'à 6 fléchettes pour ramener le score à 0 (sur un double).
- Échec en 6 fléchettes → 0 point, on passe à l'out suivant.

## 4. Scoring

| Finition | Points |
|---|---|
| en 2 fléchettes | 3 |
| en 3 fléchettes | 2 |
| en 4, 5 ou 6 fléchettes | 1 |
| **out 99 en 3 fléchettes** | **3** (exception : 99 ne peut pas se finir en 2 fléchettes) |
| échec (après 6 fléchettes) | 0 |

**Score maximum = 120.**

## 5. Fin de partie

- Le drill se termine après la **40ᵉ cible (out 100)**.
- Pas de gagnant (solo) ; le résultat = total des points sur les 40 cibles.

## 6. Conformité de l'implémentation

> Vérifié 2026-06-19 : `stateless_catch_40_engine.dart` **correspond au canonique** — séquence
> 61→100 (40 cibles), 6 fléchettes, barème 3/2/1, exception 99→3, plafond 120, solo. Aucune
> divergence connue. (Les commentaires d'en-tête de l'engine portent le barème ; ce doc le
> formalise comme oracle indépendant.)

## 7. Heuristiques de test (engine vs CE doc)

- Cible affichée == `61 + nombre de cibles déjà passées` ; 40ᵉ = 100.
- Barème exact, **dont l'exception 99→3** (seul out où 3 fléchettes valent 3 pts).
- Plafond 120 ; `successes ≤ attempts` ; scores monotones non-décroissants.
- Checkout exige un double ; échec en 6 → 0 pt et passage à l'out suivant.
- Bornes : fin après l'out 100 ; apparition en History.
