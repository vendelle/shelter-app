# Vercel Branch Deployment Configuration

Quick reference for setting up Vercel deployments with environment-specific database connections.

## Setup Checklist

### ✅ Step 1: Confirm your Neon Databases

- [ ] **TEST Database**: Connection string available
  - Used for: Development, demo, main branch
  - URL: `postgres://[user]:[password]@[host]/[testdb]`

- [ ] **ASY Production Database**: Connection string available
  - Used for: asy-production branch only
  - URL: `postgres://[user]:[password]@[host]/[asydb]`

### ✅ Step 2: Configure Vercel Environment Variables

Go to [Vercel Dashboard](https://vercel.com/dashboard):

1. Select your shelter-app project
2. Go to **Settings** (gear icon) → **Environment Variables**

#### For `main` branch (all environments):
```
Name:  A_DATABASE_URL
Value: [paste TEST_DATABASE_URL from Neon]
Environments: 
  ✅ Production
  ✅ Preview
  ✅ Development
Apply to:
  ✅ main branch
```

#### For `asy-production` branch (production only):
```
Name:  A_DATABASE_URL
Value: [paste ASY_DATABASE_URL from Neon]
Environments:
  ✅ Production only  (IMPORTANT: ONLY Production)
  ❌ Preview
  ❌ Development
Apply to:
  ✅ asy-production branch only
```

### ✅ Step 3: Create `asy-production` Branch in GitHub

```bash
git checkout -b asy-production main
git push -u origin asy-production
```

### ✅ Step 4: (Optional) Protect `asy-production` Branch

GitHub → Repository Settings → Branches → Add Rule:

- Branch name pattern: `asy-production`
- ✅ Require pull request reviews (minimum: 1)
- ✅ Require status checks to pass
- ✅ Dismiss stale pull request approvals
- ✅ Restrict who can push (admin only)
- ✅ Do NOT allow force pushes

## Verification

After setup, verify the connection:

1. **Test deployment on main**:
   - Make a small change on any branch
   - Push to main
   - Check Vercel deployment logs
   - Verify API connects correctly

2. **Test deployment on asy-production**:
   - Merge a change to asy-production
   - Check Vercel deployment logs
   - Verify API uses correct (ASY) database

## Environment Variable Precedence

Vercel applies env vars in this order (first match wins):

1. Branch-specific (e.g., `asy-production` value)
2. Environment-specific (e.g., Production vs Preview)
3. Default/global value

This ensures:
- `main` branch → Always uses TEST_DATABASE_URL
- `asy-production` branch → Always uses ASY_DATABASE_URL
- Preview PRs from main → Uses TEST_DATABASE_URL (same as main)

## Troubleshooting

### "Connection failed" error in logs

1. Check variable name is exactly `A_DATABASE_URL`
2. Verify value is complete connection string (not redacted)
3. Ensure Neon database is accessible from Vercel IP (usually automatic)
4. Test connection locally: `psql [YOUR_DATABASE_URL]`

### Wrong database in deployment

1. Go to Deployment → Settings
2. Check Environment Variables applied
3. Verify scope (branch + environment)
4. Redeploy after fixing

### Preview deployments using product DB

1. Check: Preview environment should use TEST_DATABASE_URL
2. If using main branch preview: Should inherit main's env vars
3. Verify branch is NOT set to `only asy-production`

## Reference

- [Vercel Env Vars Documentation](https://vercel.com/docs/projects/environment-variables)
- [Neon Connection Strings](https://neon.tech/docs/connect/connect-from-any-app)
- See: [DATABASE_STRATEGY.md](./DATABASE_STRATEGY.md) for full architecture
