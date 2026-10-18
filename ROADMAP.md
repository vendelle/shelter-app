# Roadmap

Working plan for the next releases. One item per Claude session: start a new
session with "zrób <punkt> z ROADMAP.md", agree on the plan first, then build.
Details of what's already built live in DECISIONS.md.

## Done (on `main`, not yet on `asy-production`)

- Google sign-in, roles (pending → volunteer → admin → super_admin), email invites, Manage → Users — #26
- App visible only to approved accounts; day plans editable 2 days back … 2 days ahead (super admin: any day)
- Dog data from the shelter website: profile with photo, facts, description; nightly cron for current dogs; admins accept/ignore the website's kennel — #28
- Nightly encrypted DB backup (GitHub Action) — #27

## Release 1 — announce sign-in to everyone

Goal: people sign in and immediately have something useful to do.

### 1.1 Export role for the shelter (S)
- New role `exporter`, **outside** the volunteer → admin ladder: after sign-in it sees only a CSV export screen (date range → download walks). No planner, dogs, volunteers or anything else.
- API: `GET /api/walks?format=csv` allowed for `exporter` and approved volunteers; every other endpoint keeps rejecting it.
- Invited like everyone else (Manage → Users, any Google account — a Google account can be created for a work email).
- Logged in the audit log once 2.1 exists.

### 1.2 Welcome / sign-in screen (S)
- Sign-in screen (`AuthGate`) with photos of the group's dogs (from `dog_shelter_profiles.photo_url`) and a short intro.
- Note: photos need the API to serve a few photo URLs to signed-out visitors, or a static set — decide in the session.

### 1.3 First sign-in: "which dogs do you walk?" (M)
- On first sign-in a volunteer fills in their dog familiarity (dobrze / trudno / nigdy), pre-filled with dogs they walked in the last ~3 months.
- Needs the account linked to a volunteer profile. Open question: let people pick "I am <volunteer>" themselves (super admin can correct it in Users), or keep linking admin-only?

### 1.4 Release checklist (`main` → `asy-production`)
1. Back up the production DB (Actions → DB backup → Run workflow).
2. Run `api/migrations/007_users.sql` and `009_exporter_role.sql` on the production DB (`008_dog_shelter_profiles.sql` is already done).
3. Vercel (asy, Production): `SUPER_ADMIN_EMAILS`, `CRON_SECRET`.
4. Firebase → Authentication → Authorized domains: the production domain.
5. Open a PR `main` → `asy-production`, merge.
6. Fill the dog data once, so the sign-in screen has photos right away: Vercel (asy) → Settings → Cron Jobs → Run. The cron runs only on the production deployment, never on previews; after this it runs nightly.
7. Invite volunteers (Manage → Users) and announce.

## Release 2

### 2.1 Edit history (M)
- Table `audit_log` (who, action, entity, entity id, old/new values as JSON, when), written by the API on every change.
- Later: "last changed by …" in the UI.

## Release 3

### 3.1 Notifications (L)
- First in the app: a bell with "new walk for you", "new dog in the group", "<dog> adopted".
- Later push notifications via Firebase Cloud Messaging. Browsers: desktop and Android work; iPhone only when the site is added to the Home Screen (iOS 16.4+). Needs a service worker — the app currently builds with `--pwa-strategy=none` because of stale caches in Facebook's in-app browser, so this needs care.

## Backlog (no order)

- **Backups — paused.** Make a backup readable on the Mac: plan was plain-SQL dump + `gpg` (standard) and opening it with GPG Suite; an `openssl` variant and a restore workflow exist on branch `chore/backup-verify` (not merged). Agree on a plan before continuing.
- Make the repo private (backups are encrypted either way).
- Chrome reports the sign-in popup as blocked — investigate.
- Showcase Vercel project (deploys `main`, has no `users` table): freeze, give it its own demo DB, or remove.
- Stable test domain (e.g. `asy-test.vercel.app`) so Firebase needn't get every preview URL.
- Shelter photos rely on `<meta name="referrer" content="no-referrer">` (their hotlink protection). If the shelter gets a web admin again, ask them to allow our domain.
- Noto font warning in the browser console (a character missing from the default font).
- `api/dayplan.ts` runs `BEGIN`/`COMMIT` on the pool, not one client — not a real transaction.
- Volunteers can change the whole day plan, including other people's assignments — revisit if it causes trouble.
- Second person with access to Vercel, Neon and Firebase, and a short "how it's set up" doc.
