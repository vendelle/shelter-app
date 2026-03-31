# Shelter Walk Tracker

A full-stack web application for managing daily dog walk schedules at an animal shelter. Volunteers use it to plan which dogs they'll walk each day, track walk history, and coordinate group walks.

**Live:** Deployed on Vercel

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (Dart) |
| State Management | Riverpod |
| Routing | go_router |
| Backend | Vercel Serverless Functions (TypeScript/Node.js) |
| Database | Neon PostgreSQL |
| CI/CD | GitHub Actions |

## Features

- **Walk Planner** — Assign dogs to volunteers for a specific date. Supports group walks (color-coded), per-dog notes, and per-volunteer notes.
- **Walk Overview** — Dashboard showing all dogs with this-week and last-week walk counts, sorted by urgency.
- **Responsive Layout** — 1-column on mobile, 2+ columns on wider screens using `Wrap`.

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp + theme + router
├── core/
│   ├── api/                  # ApiClient, providers
│   └── theme/                # App theme
├── routing/                  # go_router config (3 tabs)
└── features/
    ├── overview/             # Walk dashboard
    │   ├── data/             # ApiOverviewRepository
    │   ├── domain/           # DogWalkSummary model
    │   └── presentation/     # OverviewScreen
    ├── planner/              # Daily walk planner
    │   ├── data/             # ApiPlannerRepository
    │   ├── domain/           # VolunteerAssignment, DogEntry, PlannerDog
    │   └── presentation/
    │       ├── providers/    # PlannerNotifier (StateNotifier)
    │       └── widgets/      # VolunteerColumn, DogPicker, DateNavigator
    └── shared/
        └── domain/           # Volunteer model

api/                          # Vercel serverless functions
├── connection.ts             # Lazy PostgreSQL pool
├── util.ts                   # CORS headers, error handling
├── dogs.ts                   # GET /api/dogs
├── volunteers.ts             # GET /api/volunteers
├── dogs-walks.ts             # GET /api/dogs-walks (with walk counts)
├── dayplan.ts                # GET/POST /api/dayplan (full planner state)
├── health.ts                 # GET /api/health (diagnostics)
├── __tests__/                # Jest tests (41 tests, 100% line coverage)
└── migrations/               # SQL migration scripts
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11.0
- Node.js ≥ 20
- A Neon PostgreSQL database (or any PostgreSQL instance)

### Local Development

```bash
# Install dependencies
flutter pub get
npm install

# Run the app (uses deployed Vercel API in debug mode)
flutter run -d chrome

# Run backend tests
npm test

# Run frontend tests
flutter test

# Type-check backend
npx tsc --noEmit

# Lint frontend
flutter analyze
```

### Environment Variables

Set in Vercel dashboard (Settings → Environment Variables):

| Variable | Description |
|----------|-------------|
| `DEV_DATABASE_URL` | Neon PostgreSQL connection string |

Fallback: `DATABASE_URL` (if `DEV_DATABASE_URL` is not set).

### Deployment

Push to `main` → Vercel auto-deploys. The build:
1. Installs npm packages
2. Clones Flutter SDK
3. Builds Flutter web (`flutter build web --release`)
4. Deploys serverless API functions + static web assets

## Testing

| Suite | Command | Tests | Coverage |
|-------|---------|-------|----------|
| Backend (Jest) | `npm test` | 41 | 100% statements/lines |
| Frontend (Flutter) | `flutter test` | 72 | Models, state, widgets |

CI runs automatically on push/PR to `main` via GitHub Actions. Coverage thresholds enforced: 90% statements, 80% branches.

## Database

PostgreSQL hosted on Neon. Migrations in `api/migrations/` are idempotent (`IF NOT EXISTS`).

### Key Tables

- `dogs` — Dog inventory (name, kennel, shelter ID, archived flag)
- `volunteers` — Volunteer roster (first/last name)
- `walks` — Walk assignments (dog, volunteer, date, notes, group_index, soft-delete via `deleted_at`)
- `day_plan_volunteer_notes` — Per-volunteer notes for a specific date
