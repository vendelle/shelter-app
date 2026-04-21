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

## API Strategy: Repository pattern with swappable implementations

**Decision**: Use abstract repository interfaces, start with mock implementations, swap to real API calls when ready.

**Why?**
- Building against mock data let us iterate on UI independently of API/infra work.
- The repository pattern meant swapping to real HTTP calls was a one-line provider override.
- Mock implementations remain useful for testing — no network dependencies.

**Current state**: Mock repositories have been replaced with `ApiOverviewRepository` and `ApiPlannerRepository` that call the Vercel endpoints. The provider binding was the only change needed — all UI code remained untouched.

---

## HTTP Client: http (not dio)

**Decision**: Use the `http` package for API calls.

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

---

## Backend: Vercel Serverless Functions (not Express/Fastify)

**Decision**: Use Vercel serverless functions (TypeScript) instead of a traditional Node.js server.

**Why?**
- Zero infrastructure management — no servers to provision, patch, or scale.
- Scales to zero when unused — stays within free tier for a small shelter app.
- Each endpoint is a standalone file (`api/dogs.ts`, `api/dayplan.ts`) — simple to reason about.
- Vercel's filesystem routing maps URLs to files automatically.
- The Vue app (puszek) already uses this pattern — shared conventions across projects.

**Trade-offs:**
- Cold starts (~200ms) — acceptable for an internal tool.
- No WebSocket support — all data is request/response, which fits the workflow.
- No shared in-memory state between requests — each invocation is isolated.

---

## Lazy Database Pool via Proxy Pattern

**Decision**: Use a JavaScript `Proxy` to lazily initialize the PostgreSQL connection pool on first query, not at module import time.

**Why?**
- Vercel executes module-level code at import time. If the pool is created at import and the DB is unreachable, *every* endpoint fails — including the health check.
- Lazy init defers pool creation to the first actual query. The health endpoint can detect and report failures gracefully.
- Discovered after debugging `FUNCTION_INVOCATION_FAILED` errors in production where top-level pool creation crashed all routes.

**Alternatives considered:**
- Top-level try/catch: still crashes at import time in some cases.
- Per-request pool creation: too expensive, loses connection pooling.

---

## Soft Deletes for Walks

**Decision**: Use a `deleted_at` timestamp instead of `DELETE FROM walks`.

**Why?**
- Walk history is valuable — the shelter may want to audit "who walked which dog when."
- Soft deletes are reversible — accidental removals can be recovered.
- The planner's save logic diffs existing vs. new walks: soft-delete makes the comparison straightforward (mark removed walks, don't physically delete).

**Trade-off:** Queries must filter `WHERE deleted_at IS NULL` — mitigated by consistent query patterns across all endpoints.

---

## Debug Mode API Routing

**Decision**: In debug mode (`flutter run`), route API calls to the deployed Vercel instance instead of localhost.

**Why?**
- Flutter's dev server doesn't serve `/api/*` routes — it returns `index.html` for everything.
- Running a local Node server alongside Flutter adds friction for development.
- The Vercel deployment is always available and matches production behavior.
- Override available via `--dart-define=API_BASE_URL=...` for custom setups.

**Trade-off:** Local dev hits the real DEV database — acceptable since it's the DEV instance, not production.

---

## Group Index as Column (not a separate table)

**Decision**: Store walk groups as an integer `group_index` column on the `walks` table, not as a separate `walk_groups` join table.

**Why?**
- Groups are per-date, per-volunteer — they describe a property of a walk assignment, not an independent entity.
- Integer maps directly to a color palette array (0 = first color, 1 = second, etc.).
- No need for group names or metadata — the meaning is simply "these dogs walk together."
- Simpler queries: one column vs. a JOIN.

**When to revisit:** If groups need names, shared notes, or other metadata.

---

## Idempotent Migrations (no framework)

**Decision**: Use `IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS` in numbered SQL files instead of a migration framework.

**Why?**
- Single environment (DEV) with one developer — migration coordination isn't needed.
- Idempotent SQL is safe to re-run — no risk of applying a migration twice.
- Numbered filenames (`001_`, `002_`) establish execution order.
- Avoids adding a migration framework dependency (Knex, Prisma) for a few schema changes.

**When to revisit:** Multiple environments, team size > 1, or frequent schema changes.

---

## Testing Strategy: Unit + Widget Tests (no E2E)

**Decision**: Prioritize unit tests and widget tests over end-to-end integration tests.

**Why?**
- Unit tests for domain models and API endpoints catch the most bugs per effort.
- Widget tests verify UI rendering and interaction without a running backend.
- E2E tests (`integration_test`) require a running app + API server — high CI setup cost for marginal benefit at this scale.
- Backend tests mock the database pool (`jest.mock`) — fast, isolated, 100% line coverage.
- Frontend tests use `ProviderScope` overrides to inject mock data — no HTTP calls.

**Coverage targets:** 90% statements, 80% branches (enforced in CI via `jest --coverage`).

---

## CORS: Allow All Origins

**Decision**: Set `Access-Control-Allow-Origin: *` on all API responses.

**Why?**
- In production, the Flutter web app and API are on the same Vercel domain — CORS isn't technically needed.
- Wildcard simplifies local development (Flutter dev server runs on a different port).
- No cookie-based auth — the API is stateless, so `*` is safe.

**When to revisit:** If authentication with cookies/sessions is added (restrict to specific origins).

---

## Authentication: Firebase Auth with Google Sign-In

**Decision**: Use Firebase Authentication with Google Sign-In as the identity provider, combined with a custom backend user table for role-based authorization.

**Why Firebase Auth (not custom email/password)?**
- All shelter volunteers already have Google accounts (shared Google Drive).
- Google Sign-In is one-tap on mobile, popup on web — minimal friction.
- Firebase Auth is free (unlimited email/social sign-ins on the Spark plan).
- No password management, reset flows, or email verification to build.
- Plays well with future mobile apps (same Firebase project).

**Why not the `firebase-admin` SDK on the backend?**
- `firebase-admin` is ~50MB and causes slow cold starts on Vercel serverless functions.
- Instead, we verify Firebase ID tokens using Google's public key certificates directly — lightweight, zero-dependency, same security guarantees.
- Token verification uses `crypto.verify()` (Node.js built-in) with cached Google certs.

**Why not Facebook Login?**
- Meta Developer review process (days/weeks), requires published privacy policy.
- Higher maintenance: Meta SDK changes frequently.
- Firebase Auth supports adding Facebook later with account linking — no code architecture changes needed.

**Why a backend `users` table (not just Firebase)?**
- Firebase doesn't know about shelter-specific concepts (volunteer links, roles, approval flow).
- Our backend stores: `role` (pending → volunteer → admin → super_admin), `volunteer_id` link, approval status.
- The API verifies the Firebase token, then checks the backend user for authorization decisions.

---

## Authorization: 4-Tier Role System

**Decision**: Four roles with increasing permissions: `pending`, `volunteer`, `admin`, `super_admin`.

| Role | Who | Permissions |
|------|-----|-------------|
| **Anonymous** | Anyone with the URL | View all plans (any date), view dog overview |
| **Pending** | Signed in, not yet approved | Same as anonymous |
| **Volunteer** | Approved by super_admin | Edit day plans, edit own familiarity preferences |
| **Admin** | Trusted managers | Add/edit/archive dogs and volunteers |
| **Super Admin** | App owner + designated person | All admin powers + user approval + role management |

**Why not link permissions to volunteer seniority?**
- Shelter seniority reflects experience with dogs, not technical trust or app needs.
- A "senior" volunteer might only check plans on their phone; a "new" volunteer who's a developer might manage the dog list.
- Roles reflect the person's needs in the app, not their shelter status.

**Why separate `admin` from `super_admin`?**
- Admins manage shelter data (dogs, volunteers).
- Super admins manage access control (approvals, role changes).
- This separation prevents accidental permission escalation — an admin can't grant themselves super_admin.
- With <10 people needing admin access, this is practical without being overcomplicated.

**Why keep day plans open for anonymous viewing?**
- The app's core value is letting anyone check the plan — older volunteers, quick phone access.
- Editing requires login because the backend must attribute changes to a user.

---

## Approval Flow

**Decision**: New accounts start as `pending` and must be approved by a `super_admin`.

**Why?**
- The app URL is known within the shelter community; anyone could sign up.
- Approval prevents unauthorized access to admin features.
- Pending users still have anonymous-level access — no incentive to avoid signing up.

**How volunteer linking works:**
1. During sign-up, the user picks "I am [Volunteer Name]" from a dropdown (self-service).
2. Super admin sees the claimed link during approval and confirms it.
3. The volunteer link is unique — one user per volunteer profile (prevents duplicates).

---

## Familiarity Preferences: Login Required

**Decision**: Editing volunteer-dog familiarity preferences requires authentication.

**Why?**
- Preferences are personal ("I don't want to walk dog X") — ownership matters.
- Google Sign-In is one tap — minimal friction for the volunteer.
- Logged-in preferences enable future features: auto-fill from walk history, personal notifications.
- Volunteers can only edit their own preferences; admins can edit anyone's.
- Viewing familiarity data stays open (planners need it during planning).

---

## Auth Token Handling

**Decision**: Firebase ID token is attached to every API request as `Authorization: Bearer <token>`.

**Why?**
- Stateless — no sessions, no cookies, works across platforms.
- CORS-safe with `Access-Control-Allow-Headers: Authorization`.
- Token expires after 1 hour; Firebase SDK handles refresh automatically.
- Backend endpoints decide individually whether auth is required or optional.

**Graceful degradation:**
- If no token is present, the user is treated as anonymous.
- If the token is invalid/expired, endpoints that require auth return 401.
- The Flutter app catches 401 and prompts login.

---

## Audit Trail (Future-Ready Design)

**Decision**: Design for audit logging but don't implement it yet.

**Why defer?**
- The current volunteer group uses a Google Sheet where "who changed what" is visible.
- The `users` table with `last_login_at` provides basic activity tracking.
- A full audit log (who, what, when, old/new values) is planned for a future iteration.

**Planned schema (not yet created):**
```sql
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id INTEGER,
    changes JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**What this enables later:**
- "Last edited by [Name]" labels in the UI
- Change history per dog/volunteer/plan
- Rollback capability (JSONB stores old values)
