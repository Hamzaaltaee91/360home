# State Management Choice

## Decision

**Riverpod** (`flutter_riverpod`) is the state management solution for Dabberli.

## Rationale

- **Compile-time safety** — Providers are declared as top-level globals, so missing
  or misconfigured providers surface as compile errors rather than runtime
  `ProviderNotFoundException`s.
- **Testability** — `ProviderContainer` and `ProviderScope` overrides make it
  trivial to inject mock Supabase clients and fake services in unit and widget
  tests without touching the widget tree.
- **No `BuildContext` coupling** — Providers can be read from services, isolates,
  and background callbacks, which suits the Supabase realtime subscriptions used
  by `notification_service.dart`.
- **Composability** — `ref.watch` / `ref.listen` allow derived state (e.g. a
  filtered offers list) to rebuild only the widgets that depend on it.
- **Ecosystem fit** — Works cleanly alongside `go_router` (via `refreshListenable`
  or a router provider) and `supabase_flutter` streams.

## Conventions

- One provider file per domain under `lib/providers/`:
  - `auth_provider.dart` — global authentication state.
  - `user_provider.dart` — current user session and profile data.
  - `requests_provider.dart` — buyer requests state.
  - `offers_provider.dart` — realtor offers state.
  - `notifications_provider.dart` — notification stream state.
- Use `AsyncNotifierProvider` for state backed by async Supabase calls.
- Use `StreamProvider` for realtime Supabase subscriptions.
- Expose immutable state objects; mutate only through notifier methods.
- Wrap the app root in a single `ProviderScope` in `main.dart`.

## Alternatives Considered

- **Bloc** — More boilerplate per feature and heavier ceremony for the relatively
  small number of stateful domains here. Riverpod's `AsyncNotifier` covers the
  same async lifecycle with less code.
- **Provider (legacy)** — Superseded by Riverpod; lacks compile-time safety.
- **setState only** — Insufficient for cross-screen auth, realtime notifications,
  and shared request/offer caches.
