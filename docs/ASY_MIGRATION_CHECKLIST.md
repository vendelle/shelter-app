# ASY Production Database Migration Checklist

**Purpose**: Guide for applying new schema changes to the ASY shelter production database.

**Status**: To be determined after comparing current ASY DB state with latest migrations

**⚠️ IMPORTANT**: 
- This is production data. Mistakes are serious.
- Always backup BEFORE running migrations
- Test migrations on dev database FIRST
- Have rollback plan ready

---

## Pre-Migration Checklist

### Step 1: Understand What Changed

Since the ASY database was created (snapshot from puszek development):

**New migrations committed**:
- [ ] `001_planner_metadata.sql` - Adds walk groups + volunteer notes
  - Adds `group_index` to walks table
  - Creates `day_plan_volunteer_notes` table
  
- [ ] `002_manage_data.sql` - Manage tab features
  - Adds `archived` to volunteers
  - Adds `role` to volunteers (seniority levels)
  - Creates `volunteer_dog_familiarity` table

### Step 2: Backup ASY Database

**Critical**: Do this BEFORE running any migrations

1. Go to [Neon Console](https://console.neon.tech/)
2. Select your project
3. Click **Databases** → [ASY Database]
4. Click **Backups** → **Create Backup**
5. **Wait** for backup to complete (shows timestamp)
6. Note the backup name/date for reference

✅ Backup created and ready for rollback if needed

### Step 3: Verify Current ASY Schema

Check what tables/columns currently exist:

```sql
-- Connect to ASY DB
psql $ASY_DATABASE_URL

-- List all tables
\dt

-- Check walks table structure
\d walks

-- Check volunteers table structure
\d volunteers

-- Check for existing migration tables
SELECT * FROM information_schema.tables 
WHERE table_schema = 'public';
```

**Document current state**:
- [ ] walks table has `group_index`? YES / NO
- [ ] `day_plan_volunteer_notes` table exists? YES / NO
- [ ] volunteers table has `archived`? YES / NO
- [ ] volunteers table has `role`? YES / NO
- [ ] `volunteer_dog_familiarity` table exists? YES / NO

---

## Migration Execution

### Option A: Manual SQL (Recommended First Time)

This lets you see exactly what's happening and catch errors:

**Step 1: Test on Dev Database**

```bash
# Connect to TEST database (safe to modify)
psql $TEST_DATABASE_URL

# Run both migrations
\i api/migrations/001_planner_metadata.sql
\i api/migrations/002_manage_data.sql

# Verify success
\dt
```

**Step 2: Run on ASY Database**

```bash
# ⚠️ PRODUCTION: Stop here if dev test failed

# Connect to ASY DB
psql $ASY_DATABASE_URL

# Run migrations (same as dev)
\i api/migrations/001_planner_metadata.sql
\i api/migrations/002_manage_data.sql

# Verify success
\dt
```

**✅ Migrations applied to ASY**

### Option B: Automated Script (After Testing)

Create a single migration script that bundles all updates:

```bash
cat api/migrations/001_planner_metadata.sql \
    api/migrations/002_manage_data.sql > /tmp/asy_migration_all.sql

psql $ASY_DATABASE_URL < /tmp/asy_migration_all.sql
```

---

## Post-Migration Verification

### Step 1: Verify Schema Changes

```sql
-- Connect to ASY DB
psql $ASY_DATABASE_URL

-- ✅ Check walks table
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'walks' AND column_name = 'group_index';
-- Expected: group_index | integer

-- ✅ Check volunteers table
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'volunteers' AND column_name IN ('archived', 'role')
ORDER BY column_name;
-- Expected: archived | boolean, role | text

-- ✅ Check new tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'day_plan_%';
-- Expected: day_plan_volunteer_notes

SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'volunteer_dog_familiarity';
-- Expected: volunteer_dog_familiarity
```

### Step 2: Verify Data Integrity

```sql
-- ✅ Check no data loss
SELECT COUNT(*) FROM walks;
SELECT COUNT(*) FROM volunteers;
SELECT COUNT(*) FROM dogs;
-- Should match before-migration counts

-- ✅ Check constraints
SELECT * FROM day_plan_volunteer_notes LIMIT 0;  -- Should succeed
SELECT * FROM volunteer_dog_familiarity LIMIT 0;  -- Should succeed
```

### Step 3: Deploy App Code

Once schema verified, merge app code to `asy-production`:

```bash
git push origin setup/asy-db-schema-migration
# Create PR: setup/asy-db-schema-migration → asy-production
# Merge after app code verified on main
```

---

## Rollback Procedure (If Something Goes Wrong)

**Do NOT panic. Neon backups have you covered.**

### Automated Rollback

1. Go to [Neon Console](https://console.neon.tech/)
2. Select project → **Databases** → [ASY Database]
3. Click **Backups**
4. Find backup from before migration
5. Click **Restore**
6. ⏳ Wait for restore to complete

### Manual Rollback (If Needed)

```bash
# Get list of backups
curl -X GET "https://api.neon.tech/v2/projects/{project_id}/backups" \
  -H "Authorization: Bearer $NEON_API_KEY"

# Restore specific backup
curl -X POST "https://api.neon.tech/v2/backups/{backup_id}/restore" \
  -H "Authorization: Bearer $NEON_API_KEY"
```

✅ Database restored to pre-migration state
✅ No app code changes needed (old code works with old schema)

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| **"Column already exists"** | Migration was already applied | Check schema (Step 1) and skip that migration |
| **"Foreign key violation"** | Data references non-existent records | Likely data integrity issue; contact Neon support |
| **Connection timeout** | ASY DB not accepting connections | Check Neon status, verify connection string |
| **Constraint error** | Migration creates invalid state | Roll back and debug locally before retrying |

---

## Sign-Off Checklist

- [ ] ASY database backed up (and backup verified)
- [ ] Migrations tested on TEST database
- [ ] Migrations run on ASY database
- [ ] Schema verified (all tables/columns present)
- [ ] Data integrity verified (no data loss)
- [ ] No constraint violations
- [ ] App code merged to `asy-production`
- [ ] Vercel deployment successful
- [ ] App connects to ASY DB (check logs)

✅ **ASY production database successfully migrated**

---

## Reference

- **Migration files**: `api/migrations/`
- **Database strategy**: See `docs/DATABASE_STRATEGY.md`
- **Vercel setup**: See `docs/VERCEL_BRANCH_CONFIG.md`
- **Neon docs**: https://neon.tech/docs/guides/migrations
