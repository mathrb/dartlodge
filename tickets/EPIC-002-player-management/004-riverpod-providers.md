# TICKET-004: Riverpod Providers

**Status:** Complete
**Epic:** EPIC-002 — Player Management

---

## Description

Implement the three Riverpod providers that expose player data to the UI: a stream-backed list provider, a single-player lookup provider, and a form notifier for create/edit operations.

---

## Acceptance Criteria

- [ ] `allPlayersProvider` — `@riverpod` `AsyncNotifierProvider` that watches `watchAllPlayers()` stream; auto-disposes
- [ ] `playerProvider(String id)` — family provider returning `AsyncValue<Player?>` for a single player by UUID
- [ ] `CreatePlayerNotifier` — `@riverpod` `AsyncNotifier<void>` managing `PlayerFormState`; exposes `setName()`, `submit()`, `reset()`
- [ ] `submit()` validates name (non-empty, ≤ 30 chars), checks uniqueness against `getAllPlayers()`, then calls `createPlayer()`
- [ ] `submit()` throws `DuplicatePlayerException` as a user-visible form error, not a crash
- [ ] All providers use `AsyncValue.guard()` for async operations — no manual try/catch
- [ ] `playerRepositoryProvider` is read via `ref.watch` in `build()`, `ref.read` in event handlers
- [ ] All code generated with `@riverpod`; generated file committed

---

## Files

- `lib/features/players/presentation/providers/players_provider.dart` — to create
- `lib/features/players/presentation/providers/players_provider.g.dart` — to generate

---

## Implementation Notes

- `allPlayersProvider` should `ref.watch` the stream from `watchAllPlayers()` using `ref.watch(playerRepositoryProvider).watchAllPlayers()` inside `build()`, converting the `Stream` to `AsyncValue` automatically via Riverpod's stream support.
- `playerProvider` is a family; prefer `ref.watch(allPlayersProvider)` and filter in-memory to avoid a second database round-trip if the list is already loaded.
- `CreatePlayerNotifier.submit()` sets `isSubmitting = true` on entry and `false` on exit (success or error) using `state = state.copyWith(isSubmitting: ...)`. It does **not** use `AsyncValue.loading()` on `state` — the form state remains visible while submitting.
- Uniqueness check: `getAllPlayers()` then `any((p) => p.name.toLowerCase() == name.toLowerCase())`. Case-insensitive comparison prevents "Alice" and "alice" coexisting.
- On successful `submit()`, the notifier does not navigate — it emits a completion signal that the page listens to (e.g., via `ref.listen`) to call `context.pop()`.
