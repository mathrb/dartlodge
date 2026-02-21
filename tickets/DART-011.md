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

- [ ] `ProcessDartUseCase` is provided via a dedicated Riverpod provider
- [ ] `ActiveGameProvider` reads the use case via `ref.read(processDartUseCaseProvider)`
- [ ] Tests can override `processDartUseCaseProvider` and have the override take effect
- [ ] No other use case is constructed inline in any notifier

