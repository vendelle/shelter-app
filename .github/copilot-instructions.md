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

- **Run `flutter analyze` before committing** — must report **zero issues** (errors and warnings). Info-level hints are acceptable unless they're actionable deprecations.
- **Run coverage check for API changes:**
  ```bash
  npm test -- --ci --coverage --coverageThreshold='{"global":{"statements":90,"branches":80,"functions":90,"lines":90}}'
  ```
  Must meet all thresholds: **statements ≥90%**, **branches ≥80%**, **functions ≥90%**, **lines ≥90%**
- Run `npx jest` for API changes — all tests must pass
- Run `flutter test` for Flutter changes — all tests must pass
- Write tests for every new feature (Flutter widget/unit tests + API unit tests)
- Use `// ignore: <rule>` comments only when:
  - A Flutter API is deprecated but the replacement isn't available in the current SDK version (add TODO with migration path)
  - External package has unavoidable warnings
  - Always document the reason inline with the ignore comment

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
