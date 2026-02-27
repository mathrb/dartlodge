# EPIC-010: Backend Sync & Authentication

## Goal
Optionally connect the app to a self-hosted backend for account creation, JWT authentication, and event log synchronisation across devices.

## Status
[ ] Not started

> **Prerequisite:** Do not begin this epic until EPIC-001 through EPIC-009 are fully working end-to-end locally. No backend code should be built before the core game loop is proven.

## Scope — In
- **`AuthService`:**
  - JWT login (`POST /auth/login`) and token refresh (`POST /auth/refresh`)
  - Secure token storage via `flutter_secure_storage`
  - `AuthState` (freezed): unauthenticated, authenticating, authenticated(user), error
  - Auto-refresh: intercept 401 responses, refresh token, retry original request
- **`ApiClient`** (Dio-based):
  - Base URL configurable via settings
  - Auth interceptor: injects `Authorization: Bearer <token>` header
  - Retry interceptor: exponential backoff on 5xx, max 3 retries
  - Timeout configuration
- **`SyncQueueProcessor`** (background worker):
  - Drains `sync_queue` table (schema v2) in order of `local_sequence`
  - Sends batched events to `POST /sync/events`
  - On success: marks entries as synced, updates `global_sequence`
  - On failure: exponential backoff, marks as errored after max retries
  - Pauses when offline (connectivity detection)
- **`SyncStatusNotifier`** (Riverpod `StreamNotifier`):
  - States: idle, syncing, error(message), offline
  - Exposes last-synced timestamp
- **Account linking screen:**
  - Email + password fields
  - Backend server URL field (validated as valid HTTP/HTTPS URL)
  - "Connect account" button
  - Error display (invalid credentials, server unreachable)
- **Settings screen (sync section):**
  - Server URL display + "Change" action
  - Account email display + "Disconnect" action
  - Sync status indicator + manual "Sync now" button
- **Schema v2 migration** (`onUpgrade` version 2):
  - `sync_queue` table (as defined in `docs/DATABASE_DDL.md`)
  - Applied only when backend is configured; not applied on fresh installs without a configured server

## Scope — Out
- Real-time multiplayer (not in roadmap)
- Push notifications
- OAuth / social login
- Conflict resolution beyond `local_sequence` / `global_sequence` ordering (per spec: sequence ordering is authoritative)

## Key User Stories
- As a player, I can enter my server URL and credentials to link my account so that my data backs up to my own server.
- As a player, my game events sync automatically in the background so that I don't have to think about it.
- As a player, I can see sync status (idle / syncing / error) so that I know my data is safe.
- As a player, the app works fully offline and queues events for the next sync so that connectivity issues don't interrupt games.
- As a player, I can disconnect my account and all local data remains intact so that I am not locked in.

## Technical Components
- `lib/features/auth/domain/services/auth_service.dart`
- `lib/features/auth/data/services/auth_service_impl.dart`
- `lib/features/auth/presentation/pages/account_linking_page.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/presentation/state/auth_state.dart`
- `lib/core/network/api_client.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/retry_interceptor.dart`
- `lib/core/sync/sync_queue_processor.dart`
- `lib/core/sync/sync_status_notifier.dart`
- `lib/core/sync/sync_status_state.dart`
- `lib/features/settings/presentation/pages/settings_page.dart` — sync section
- Schema v2 migration in `lib/core/persistence/database_provider.dart`

## Dependencies
- EPIC-001 (sync_queue table schema, database_provider migration support)
- EPIC-002 through EPIC-009 (all local features must be complete and stable first)

## Spec References
- `docs/API_CONTRACT.md` — REST endpoint specifications
- `docs/BACKEND_INTEGRATION.md` — sync protocol, queue format, conflict resolution
- `docs/ARCHITECTURE_COMPLETE.md` — sync protocol section
- `docs/DATABASE_DDL.md` — sync_queue table DDL (schema v2)
