# Testing rules

> Loaded on demand. CLAUDE.md's Rules Index points here before writing notifier or widget tests.
> Repository contract-test rules live in `database.md`; stat-literal finder pitfalls live in `statistics.md`.

### Notifier tests
Use `ProviderContainer` with `overrides`. Never instantiate notifiers directly. Use `ProviderScope` with `overrides` for widget tests.
