-- App user accounts (Google Sign-In via Firebase Auth) and their roles.
--
-- A row is either:
--   * an invite — created by a super_admin with an email + role, firebase_uid
--     still NULL; claimed automatically the first time that Google account
--     signs in, or
--   * a self-registered account — created on first sign-in with role 'pending'
--     until a super_admin grants a role.
--
-- Some databases already have this table from an earlier auth attempt
-- (branch feature/auth-system), so it's created in that old shape if missing
-- and then upgraded — both paths end up identical. Safe to re-run.

CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    firebase_uid    TEXT UNIQUE,
    email           TEXT UNIQUE NOT NULL,
    display_name    TEXT,
    photo_url       TEXT,
    volunteer_id    INTEGER REFERENCES volunteers(id) UNIQUE,
    role            TEXT NOT NULL DEFAULT 'pending'
                        CHECK (role IN ('pending', 'volunteer', 'admin', 'super_admin')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    last_login_at   TIMESTAMPTZ
);

-- Invites have no Firebase account yet.
ALTER TABLE users ALTER COLUMN firebase_uid DROP NOT NULL;

ALTER TABLE users ALTER COLUMN created_at SET NOT NULL;

-- Emails are stored lower-cased so invites match however they were typed.
UPDATE users SET email = lower(email) WHERE email <> lower(email);
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_lowercase;
ALTER TABLE users ADD CONSTRAINT users_email_lowercase CHECK (email = lower(email));

-- Deleting a volunteer profile unlinks the account instead of failing.
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_volunteer_id_fkey;
ALTER TABLE users ADD CONSTRAINT users_volunteer_id_fkey
    FOREIGN KEY (volunteer_id) REFERENCES volunteers(id) ON DELETE SET NULL;
