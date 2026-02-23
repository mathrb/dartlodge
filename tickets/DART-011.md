## DART-011 — `ProcessDartUseCase` instantiates use-case dependencies inline instead of via providers

**Type:** Bug / Architecture  
**Component:** `lib/features/game/presentation/providers/active_game_provider.dart`  
**Spec reference:** `STATE_MANAGEMENT.md §2 — Clean Separation`

### Description

Inside `ActiveGameProvider.processDart`, the `ProcessDartUseCase` is constructed directly:

```dart
final useCase = ProcessDartUseCase(
  ref.read(gameRepositoryProvider),
  ref.read(gameEventRepositoryProvider),
);
```

This bypasses the provider system. In tests, overriding `processDartUseCaseProvider` has no effect because the notifier never reads it. The architecture spec is explicit: *"Dependencies flow down: UI → Notifiers → UseCases → Repositories"* — use cases must be injected, not constructed inline.

### Required change

Create a dedicated provider for the use case and consume it:

```dart
// lib/features/game/presentation/providers/game_providers.dart
@riverpod
ProcessDartUseCase processDartUseCase(ProcessDartUseCaseRef ref) {
  return ProcessDartUseCase(
    ref.watch(gameRepositoryProvider),
    ref.watch(gameEventRepositoryProvider),
  );
}

// In ActiveGameProvider.processDart:
final useCase = ref.read(processDartUseCaseProvider);
```

### Acceptance criteria

- [x] `ProcessDartUseCase` is provided via a dedicated Riverpod provider
- [x] `ActiveGameProvider` reads the use case via `ref.read(processDartUseCaseProvider)`
- [x] Tests can override `processDartUseCaseProvider` and have the override take effect
- [x] No other use case is constructed inline in any notifier

### Implementation Summary

**Changes made:**

1. **Added provider in `lib/core/persistence/database_provider.dart`:**
   - Added import for `ProcessDartUseCase`
   - Created `@Riverpod` provider function `processDartUseCase()` that injects required repositories
   - Follows existing pattern with `keepAlive: true`

2. **Updated `lib/features/game/presentation/providers/active_game_provider.dart`:**
   - Replaced inline instantiation with `ref.read(processDartUseCaseProvider)`
   - Removed unused imports
   - Maintains identical functionality while fixing architecture compliance

**Verification:**
- Riverpod code generation completed successfully
- Provider is properly generated in `database_provider.g.dart`
- No other inline use case constructions exist in the codebase
- Architecture now complies with dependency injection principles

**Impact:**
- Tests can now override `processDartUseCaseProvider` for proper mocking
- Dependencies flow correctly: UI → Notifiers → UseCases → Repositories
- No breaking changes to existing functionality


---

## Review Comments (2026-02-22)

The implementation correctly addresses the architectural violation:

- **Provider:** ✅ `processDartUseCaseProvider` is now defined in `database_provider.dart`.
- **DI:** ✅ Dependencies are properly injected via the provider system.
- **Notifier:** ✅ `ActiveGameProvider` successfully switched from inline construction to provider consumption.
- **Consistency:** ✅ Verified that no other use cases are currently constructed inline in the presentation layer.

**Verdict:** ✅ **PASSED.** Architectural alignment achieved.
