# Shelter App — Copilot Instructions

## Project Context

Shelter walk planning app used by ~30 volunteers at a dog shelter in Poland.
Flutter mobile/web + Vercel serverless API (TypeScript) + PostgreSQL.

- **State management:** Riverpod (see DECISIONS.md for reasoning)
- **Routing:** go_router
- **Localization:** Polish (primary), English (secondary) — via Flutter gen-l10n
- **Backend:** Vercel serverless functions in `api/`, PostgreSQL via `pg` pool
- **Migrations:** `api/migrations/` — numbered SQL files, run manually via `psql`

## Code Quality

- Run `flutter analyze` before committing — zero errors/warnings required
- Run `npx jest` for API changes — all tests must pass
- Run `flutter test` for Flutter changes — all tests must pass
- Write tests for every new feature (Flutter widget/unit tests + API unit tests)
- No `// ignore` comments unless explicitly discussed and justified

## Commit & Branch Conventions

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- Branch naming: `feat/`, `fix/`, `refactor/` + kebab-case description
- Commit in logical chunks (one concern per commit when practical)
- PRs should have descriptive titles and body summarizing changes

## Architecture

- **Flutter:** `lib/features/<name>/` folder structure with `data/`, `domain/`, `presentation/`
- **Providers:** Riverpod `StateNotifier` + `FutureProvider` patterns
- **API:** One serverless function per file in `api/`, shared `connection.ts` pool
- **Domain models:** Plain Dart classes with `copyWith`, no code generation

## Conventions

- UI strings: always add to both `lib/l10n/app_pl.arb` (primary) and `app_en.arb`
- Decisions logged in `DECISIONS.md` when making architectural or design choices
- Keep `README.md` current — this also serves as portfolio documentation
- Prefer explicit over clever; readability over brevity
- No dead code — remove unused imports, variables, and commented-out blocks

## Testing Patterns

- Widget tests: pump the widget in a `MaterialApp`, verify rendering and interactions
- Provider tests: use `ProviderContainer` with overrides and `FakeRepository` implementations
- API tests: mock the database pool, verify SQL queries and response shapes
- Test file naming: `test/<category>/<feature>_test.dart`
