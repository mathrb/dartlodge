# TICKET-003: PlayerState & PlayerFormState

**Status:** Done
**Epic:** EPIC-002 — Player Management

---

## Description

Define the two `freezed` state classes that Riverpod notifiers will manage: `PlayerState` for the player list screen and `PlayerFormState` for the create/edit player form.

---

## Acceptance Criteria

- [x] `PlayerState` is a `@freezed` class with a `factory PlayerState.initial()` constructor
- [x] `PlayerState` fields: `players` (List<Player>), `isLoading` (bool), `error` (String?)
- [x] `PlayerFormState` is a `@freezed` class with a `factory PlayerFormState.initial()` constructor
- [x] `PlayerFormState` fields: `name` (String), `nameError` (String?), `isSubmitting` (bool)
- [x] Both classes live in `lib/features/players/presentation/state/`
- [x] Generated files are committed after running `build_runner`

---

## Files

- `lib/features/players/presentation/state/player_state.dart` — to create
- `lib/features/players/presentation/state/player_form_state.dart` — to create

---

## Implementation Notes

- `PlayerState` wraps the raw list + loading/error booleans so widgets can render all three `AsyncValue` cases without calling `.value!`.
- `PlayerFormState.nameError` holds a human-readable validation message (`null` = no error). Validation rules: non-empty, max 30 characters, unique name (uniqueness is checked by the notifier against the repository, not in the state class itself).
- `isSubmitting` on `PlayerFormState` disables the submit button while the create/update call is in flight — prevents double-tap submissions.
- Do not add a `success` flag to `PlayerFormState`. On success the notifier pops the route; it does not leave the form in a "success" state.
