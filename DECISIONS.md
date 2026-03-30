# Architectural Decisions

This document records the key architectural decisions made for the Shelter Walk Tracker app and explains the reasoning behind each one.

---

## State Management: Riverpod (not Bloc, not Provider)

**Decision**: Use `flutter_riverpod` for state management.

**Why not Bloc?**
- Bloc requires significant boilerplate (events, states, blocs) for every feature. For a data-driven app where most screens fetch and display API data, this overhead slows development without proportional benefit.
- Bloc excels when you have complex state machines with many transitions (e.g., multi-step forms, complex workflows). Our screens are mostly fetch → display → act.

**Why not Provider?**
- Provider is the predecessor to Riverpod, created by the same author (Remi Rousselet). Riverpod solves Provider's fundamental limitations:
  - No `BuildContext` dependency for accessing state — providers are global and testable.
  - Compile-time safety — typos in provider names are caught at compile time, not runtime.
  - Built-in support for async data (`AsyncValue`) with loading/error/data states out of the box.
  - Provider auto-disposal — no manual lifecycle management.

**Why Riverpod?**
- Lightweight for simple cases (a `FutureProvider` is one line), powerful enough for complex ones.
- `AsyncValue` pattern eliminates boilerplate for loading/error handling across every screen.
- Easy to swap data sources (mock → API) by overriding providers — ideal for our phased approach.
- Strong community adoption and active maintenance.
- Works identically on mobile and web (no platform-specific concerns).

---

## Routing: GoRouter (not Navigator 2.0 raw, not auto_route)

**Decision**: Use `go_router` for navigation.

**Why?**
- Declarative routing that supports deep linking, URL-based navigation (important for web target), and nested navigation.
- `StatefulShellRoute` provides tab persistence out of the box — switching tabs doesn't rebuild screens.
- Maintained by the Flutter team — low risk of abandonment.
- Simpler API than raw Navigator 2.0 or `auto_route` code generation.

**Why not auto_route?**
- Requires code generation (`build_runner`), adding complexity to the build pipeline.
- For our tab-based app with ~5 screens, GoRouter's declarative API is sufficient without generation overhead.

---

## Architecture: Feature-first (not layer-first)

**Decision**: Organize code by feature (`features/overview/`, `features/planner/`) rather than by layer (`models/`, `screens/`, `repositories/`).

**Why?**
- **Scalability**: Adding a new feature means creating a new folder, not touching 5 different directories.
- **Encapsulation**: Each feature owns its models, data layer, and UI. Changes are localized.
- **Readability**: Opening the project tells you what the app *does*, not what types of files it *has*.
- **Deletion**: Removing a feature is deleting one folder, not hunting across layers.

Within each feature, we use a lightweight `data/domain/presentation` split:
- `domain/` — plain Dart models (no framework dependencies)
- `data/` — repositories that fetch/transform data
- `presentation/` — screens, widgets, providers

---

## API Strategy: Mock repositories first, swap later

**Decision**: Use abstract repository interfaces with mock implementations for v1 development.

**Why?**
- The puszek Vue app already owns the Vercel API layer. When we're ready, the Flutter app will call those same endpoints.
- Building against mock data lets us iterate on UI independently of API/infra work.
- The repository pattern means swapping to real HTTP calls is a one-line change in the provider definition.
- Mock data also makes testing trivial — no network dependencies.

**Future plan**: When connecting to the real API, we'll add an `ApiOverviewRepository` that calls the Vercel endpoints and swap the provider binding.

---

## HTTP Client: http (planned, not dio)

**Decision**: Use the `http` package when real API calls are needed.

**Why not dio?**
- `http` is a first-party Dart package, minimal API surface, no extra dependencies.
- For our use case (simple REST calls with JSON), `http` is sufficient.
- Dio's interceptors, cancellation tokens, and retry logic are valuable for complex apps, but premature here.
- If we need interceptors (e.g., for auth headers in v2), we can migrate to dio at that point.

---

## No Auth in v1

**Decision**: Skip authentication entirely in v1. Volunteer picks their name from a dropdown.

**Why?**
- Fastest path to a working MVP that the shelter can actually use.
- Auth (email/password, JWT tokens, secure storage) is significant infrastructure for mobile.
- The existing Vue app also runs without auth — so the API doesn't enforce it yet.
- v2 will add auth (email/password with JWT), at which point we'll add `flutter_secure_storage` and an auth interceptor.

---

## Database: Shared with existing Vue app

**Decision**: Both apps share the same Neon Postgres database via the same Vercel API layer.

**Why?**
- Single source of truth — no data sync issues.
- The schema already exists and works. Adding a separate database would mean duplicating data or building sync.
- The Flutter app is just a new client for the same API — it doesn't need its own data store.

**Constraint**: Any schema changes must be backwards compatible with the Vue app until it's retired or both apps are coordinated.

---

## Theme: Material 3 with custom color scheme

**Decision**: Use Material 3 (`useMaterial3: true`) with a teal-based seed color.

**Why?**
- Material 3 is the current design standard for Flutter. Using Material 2 would look dated.
- `ColorScheme.fromSeed()` generates a cohesive, accessible color palette from a single color.
- Teal/green palette feels appropriate for an animal welfare app — calming, nature-oriented.
- Material 3 components (NavigationBar, Cards, etc.) have better defaults for mobile-first design.
