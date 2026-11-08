# Roadmap

Working plan for the next releases. One item per Claude session: start a new
session with "zrób <punkt> z ROADMAP.md", agree on the plan first, then build.
Details of what's already built live in DECISIONS.md.

## Done (on `asy-production`, Release 1 — #34)

- Google sign-in, roles (pending → volunteer → admin → super_admin), email invites, Manage → Users — #26
- App visible only to approved accounts; day plans editable 2 days back … 2 days ahead (super admin: any day)
- Dog data from the shelter website: profile with photo, facts, description; nightly cron for current dogs; admins accept/ignore the website's kennel — #28
- Nightly encrypted DB backup (GitHub Action) — #27
- Export-only role `exporter` for the shelter — #30
- Welcome / sign-in screen with dog photos — #31
- Volunteers asked to rate unrated dogs after sign-in — #32
- App renamed to AsoPsiaki — #33

## Release checklist (`main` → `asy-production`)
1. Back up the production DB (Actions → DB backup → Run workflow).
2. Run new `api/migrations/*.sql` on the production DB.
3. Check new env vars in Vercel (asy, Production).
4. Open a PR `main` → `asy-production`, merge.

## Release 2

### 2.1 Auto-fill the walks form — first
- Details to agree when we start.

### 2.2 Diego and Perez on the sign-in photos (S)

### 2.3 Add a new volunteer (S/M)

### 2.4 Walk with two volunteers (M)
- One dog walked by two volunteers together.

### 2.5 Volunteer profile: list of walks with dogs (M)

### 2.6 Automatic dog familiarity from walk history (M)
- Derive who walks which dogs from past walks instead of only manual ratings.
- Earlier idea: dogs walked in the last ~3 months on top, with their number of walks.

### 2.7 Better statistics (M)
- Details to agree when we start.

### 2.8 UI improvements
- Details to agree when we start.

## Release 3

### 3.1 Edit history (M)
- Table `audit_log` (who, action, entity, entity id, old/new values as JSON, when), written by the API on every change.
- Later: "last changed by …" in the UI.

## Release 4

### 4.1 Notifications (L)
- First in the app: a bell with "new walk for you", "new dog in the group", "<dog> adopted".
- Later push notifications via Firebase Cloud Messaging. Browsers: desktop and Android work; iPhone only when the site is added to the Home Screen (iOS 16.4+). Needs a service worker — the app currently builds with `--pwa-strategy=none` because of stale caches in Facebook's in-app browser, so this needs care.

## Backlog (no order)

- **Backups — paused.** Make a backup readable on the Mac: plan was plain-SQL dump + `gpg` (standard) and opening it with GPG Suite; an `openssl` variant and a restore workflow exist on branch `chore/backup-verify` (not merged). Agree on a plan before continuing.
- Make the repo private (backups are encrypted either way).
- Showcase Vercel project (deploys `main`, has no `users` table): freeze, give it its own demo DB, or remove.
- Stable test domain (e.g. `asy-test.vercel.app`) so Firebase needn't get every preview URL.
- Shelter photos rely on `<meta name="referrer" content="no-referrer">` (their hotlink protection). If the shelter gets a web admin again, ask them to allow our domain.
- Noto font warning in the browser console (a character missing from the default font).
- `api/dayplan.ts` runs `BEGIN`/`COMMIT` on the pool, not one client — not a real transaction.
- Volunteers can change the whole day plan, including other people's assignments — revisit if it causes trouble.
- Second person with access to Vercel, Neon and Firebase, and a short "how it's set up" doc.
