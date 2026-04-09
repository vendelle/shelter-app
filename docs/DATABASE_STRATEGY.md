# Database Strategy & Multi-Environment Setup

This document outlines the database architecture for Shelter Walk Tracker, including separation between showcase/development and production environments.

## Overview

The app uses Neon PostgreSQL with strict environment separation to protect production data while enabling safe development and public demos.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Git Branches                              │
├─────────────────────────────────────────────────────────────────┤
│  main                │  asy-production                            │
│  (Showcase/Test)     │  (ASY Shelter Live)                       │
└─────────────────────────────────────────────────────────────────┘
         ↓                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Vercel Deployments                          │
├─────────────────────────────────────────────────────────────────┤
│  main branch deploy  │  asy-production branch deploy             │
│  Preview + main      │  Production environment                   │
└─────────────────────────────────────────────────────────────────┘
         ↓                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Neon Databases (Separate)                     │
├─────────────────────────────────────────────────────────────────┤
│  TEST_DATABASE       │  ASY_DATABASE                             │
│  - Development tests │  - Live shelter operations                │
│  - Public showcases  │  - Real dog data                          │
│  - Demo volunteers   │  - Sensitive information                  │
│  - Safe to reset     │  - Backup before migrations               │
└─────────────────────────────────────────────────────────────────┘
```

## Environment Configuration

### `main` Branch (Development & Showcase)

**Purpose**:
- Public demos for interviewers and stakeholders
- Safe testing ground for new features
- Can be reset without impact

**Database**: `TEST_DATABASE_URL` (Neon project)
- Contains sample/demo data only
- Can be freely modified and reset
- No real shelter data

**Vercel Configuration**:
```
Environment Variables (main branch):
  A_DATABASE_URL = TEST_DATABASE_URL
```

**Deployment Trigger**:
- Merges to main
- Preview deployments for PRs (use same test DB)

### `asy-production` Branch (ASY Shelter Production)

**Purpose**:
- Live application for ASY (shelter group)
- Real dog, volunteer, and walk data
- **Protected and immutable** once deployed

**Database**: `ASY_DATABASE_URL` (Separate Neon project)
- Contains real shelter operations data
- Backed up before any migrations
- Treated as production data

**Vercel Configuration**:
```
Environment Variables (asy-production branch ONLY):
  A_DATABASE_URL = ASY_DATABASE_URL
```

**Deployment Trigger**:
- Merges to `asy-production`
- Only tested, production-ready code
- Code must be tested on `main` first

## Why This Separation?

### Problem: Preventing Data Contamination

The concern you had (nervousness about messing up production) is **rational and valid**. Your setup prevents it through:

| Risk | Traditional Approach | Our Approach |
|------|---|---|
| **New branch = wrong database** | Manual env var management | Vercel manages per-branch automatically |
| **Accidental schema change** | Easy to apply to wrong DB | Only `asy-production` connects to ASY DB |
| **Preview deploys affect production** | Preview might use prod DB | Preview uses test DB (same as main) |
| **Rollback difficulty** | Unclear which migrations ran | Git history + numbered migrations clear |

### Industry Best Practice

This is exactly how production applications are managed:
- ✅ GitHub organization manages branch protections
- ✅ Environment variables scoped per branch/environment
- ✅ Separate databases isolated from development
- ✅ CI/CD controls what code can reach production

## Workflow: Safe Development → Production

### Scenario 1: Adding a New Feature

1. **Create feature branch** from `main`:
   ```bash
   git checkout -b feature/new-feature main
   ```

2. **Develop & test locally**:
   - Local `.env.development.local` uses `TEST_DATABASE_URL`
   - Can reset test DB anytime
   ```bash
   flutter run -d chrome
   ```

3. **Push to GitHub & create PR**:
   - PR creates preview deployment on Vercel
   - Preview uses `TEST_DATABASE_URL` (same as main)
   - Safe to test in browser

4. **Merge to main**:
   ```bash
   git merge --no-ff feature/new-feature
   git push origin main
   ```
   - Main branch deployment uses `TEST_DATABASE_URL`
   - Shows up in public demo

5. **When ASY wants the feature**:
   - PR from `main` → `asy-production`
   - Code is already tested
   - Migration scripts reviewed & tested on `TEST_DATABASE_URL` first
   - Merge to `asy-production`
   - Vercel deploys to production using `ASY_DATABASE_URL`

### Scenario 2: Database Schema Migration

1. **Create migration file** in `api/migrations/`:
   ```
   500_add_new_field.sql
   ```

2. **Test locally**:
   - Run against local test DB copy
   - Verify no data loss

3. **Commit & merge to main**:
   - Test again on main's preview deployment
   - Confirm schema matches expected state

4. **When ready for ASY**:
   - Create [migration checklist](./ASY_MIGRATION_CHECKLIST.md)
   - **Manual step**: Run migration script on ASY DB via Neon console
   - Backup ASY DB before migration
   - Verify schema matches expected state
   - Merge app code to `asy-production`

5. **If something breaks**:
   - Neon backup + rollback
   - Revert migration on ASY DB
   - Fix code on main
   - Re-test before merging to `asy-production` again

## Setting Up Environment Variables in Vercel

### Step 1: Get Your Database URLs

**Test Database** (existing):
- Login to Neon: https://console.neon.tech/
- Find project: `TEST_DATABASE_URL`
- Copy connection string

**ASY Production Database** (new):
- Create separate database in Neon
- Copy connection string: `ASY_DATABASE_URL`

### Step 2: Configure Vercel

1. Go to: [Vercel Dashboard → Settings → Environment Variables](https://vercel.com/dashboard)

2. **For main branch**:
   ```
   Variable: A_DATABASE_URL
   Value: [paste TEST_DATABASE_URL]
   Environments: Production, Preview, Development
   Apply to: main branch
   ```

3. **For asy-production branch**:
   ```
   Variable: A_DATABASE_URL
   Value: [paste ASY_DATABASE_URL]
   Environments: Production only
   Apply to: asy-production branch only (IMPORTANT!)
   ```

✅ Now Vercel automatically uses the correct database for each branch

## Safeguards & Rollback

### Before Any ASY Database Change

1. **Always backup**:
   - In Neon console: Databases → [ASY DB] → Backups → Create
   - Wait for backup to complete

2. **Test migration on test DB first**:
   - Run migration script from `TEST_DATABASE_URL`
   - Verify success before touching ASY DB

3. **Document baseline state**:
   - Note current schema in version control
   - Keep migration scripts numbered and versioned

### If Migration Fails

1. **Do NOT panic**:
   - Neon backups are available
   - Git has all migration history

2. **Rollback via Neon**:
   - Neon console → Backups → Restore
   - Select backup from before migration
   - Wait for restore to complete

3. **Fix the code**:
   - Revert migration file
   - Fix bug
   - Test on `TEST_DATABASE_URL`
   - Re-apply to ASY DB

## Branch Protection Rules (Recommended)

To strengthen safeguards, configure GitHub:

1. Go to: Repository Settings → Branches → Add Rule

2. **For `asy-production` branch**:
   - ✅ Require pull request reviews (minimum 1)
   - ✅ Require status checks to pass
   - ✅ Require branches to be up-to-date
   - ✅ Dismiss stale reviews
   - ✅ Require review from code owners
   - ❌ Allow force pushes (never!)

This prevents accidental merges to production.

## Monitoring & Alerts

### Vercel Deployment Notifications

- ✅ Email on failed deployments
- ✅ Check Vercel logs: [Vercel Dashboard → asy-production branch → Deployments](https://vercel.com/dashboard)

### Database Monitoring (Neon)

- Login to Neon console
- Monitor connection pools and query performance
- Set up alerts for unusual activity (optional)

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| **Wrong database on main** | Incorrect env var | Check: Vercel Settings → Environment Variables → Scope |
| **ASY DB affected by PR** | PR deployed to `asy-production` | Branch protection: Only fast-forward merges from `main` |
| **Migration failed on test DB** | Script has bugs | Fix script, test locally, re-apply to test DB first |
| **Can't connect locally** | wrong `.env.development.local` | File exists? Has TEST_DATABASE_URL? Run `flutter pub get` |

## Summary

```
✅ main → TEST_DATABASE_URL (safe to demo, reset, experiment)
✅ asy-production → ASY_DATABASE_URL (protected, production data)
✅ Vercel manages env vars per branch (automatic isolation)
✅ All migrations versioned in git (repeatable, auditable)
✅ Backups available in Neon (rollback safety net)
```

You've built a production-ready system. Your nervousness is justified by industry practice, and this setup eliminates the risks.
