import 'dart:math' as math;

import 'package:dart_lodge/core/utils/checkout_table.dart';

/// Checkout-Practice target modes (#636). Stored on `CheckoutPracticeGameConfig`
/// and mirrored onto `GameState`.
const String kCheckoutModeFixed = 'fixed';
const String kCheckoutModeRandom = 'random';
const String kCheckoutModeProgressive = 'progressive';

/// Default fixed checkout target (the historical 170 drill).
const int kCheckoutDefaultTarget = 170;

/// Whether [value] is a valid double-out checkout (2..170, bogey numbers
/// excluded) — i.e. a score you can actually finish a leg on. Backed by the
/// canonical double-out table so it stays in lock-step with the suggestions.
bool isCheckoutableScore(int value) => kCheckoutTable.containsKey(value);

/// Ascending list of checkoutable values within [min]..[max] (inclusive).
List<int> checkoutableValuesIn(int min, int max) {
  final lo = math.min(min, max);
  final hi = math.max(min, max);
  return [
    for (var v = lo; v <= hi; v++)
      if (isCheckoutableScore(v)) v,
  ];
}

/// Nearest checkoutable score to [value] (prefers the value itself, then steps
/// outward; falls back to 170). Used to land progressive steps on a finishable
/// number when `start + step*n` hits a bogey.
int snapToCheckoutable(int value) {
  if (isCheckoutableScore(value)) return value;
  for (var d = 1; d <= 170; d++) {
    if (isCheckoutableScore(value - d)) return value - d;
    if (isCheckoutableScore(value + d)) return value + d;
  }
  return kCheckoutDefaultTarget;
}

/// Deterministic, replay-stable hash of [gameId] + [runIndex] used to seed the
/// random-mode picker. Explicit FNV-1a (NOT `String.hashCode`, which is not
/// guaranteed stable across runs) so a replay months later picks the same
/// targets.
int _stableHash(String gameId, int runIndex) {
  var hash = 0x811c9dc5; // FNV offset basis (32-bit)
  void mix(int byte) {
    hash ^= byte & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff; // FNV prime
  }

  for (final code in gameId.codeUnits) {
    mix(code);
    mix(code >> 8);
  }
  mix(0x3a); // ':' separator
  var idx = runIndex;
  for (var i = 0; i < 4; i++) {
    mix(idx);
    idx >>= 8;
  }
  return hash & 0x7fffffff;
}

/// The checkout target FROM which the player plays the [runIndex]-th run of a
/// Checkout-Practice drill (`runIndex` = completed checkouts so far). Pure and
/// deterministic — the engine and every stats reconstruction read the value it
/// stamps onto the run-start `TurnStarted` (`from_score`), so they all agree
/// (#636).
///
/// - [kCheckoutModeFixed]: always [fixedTarget].
/// - [kCheckoutModeProgressive]: climbs `minTarget + step*runIndex`, clamped at
///   [maxTarget] and snapped to the nearest checkoutable score.
/// - [kCheckoutModeRandom]: a checkoutable value in [minTarget]..[maxTarget],
///   chosen by `Random(_stableHash(gameId, runIndex))` so it varies per run yet
///   is stable on replay.
///
/// Malformed config (no checkoutable value in range, out-of-bounds fixed) falls
/// back to [fixedTarget] clamped into 2..170, else 170.
int checkoutTargetForRun({
  required String mode,
  required int fixedTarget,
  required int minTarget,
  required int maxTarget,
  required int step,
  required String gameId,
  required int runIndex,
}) {
  final safeFixed =
      isCheckoutableScore(fixedTarget) ? fixedTarget : snapToCheckoutable(fixedTarget);
  switch (mode) {
    case kCheckoutModeProgressive:
      final raw = minTarget + step.clamp(1, 168) * runIndex;
      final capped = math.min(raw, maxTarget);
      return snapToCheckoutable(capped);
    case kCheckoutModeRandom:
      final pool = checkoutableValuesIn(minTarget, maxTarget);
      if (pool.isEmpty) return safeFixed;
      final rng = math.Random(_stableHash(gameId, runIndex));
      return pool[rng.nextInt(pool.length)];
    case kCheckoutModeFixed:
    default:
      return safeFixed;
  }
}
