-- User accounts for authentication.
-- Each user authenticates via Firebase (Google Sign-In) and is linked
-- to an optional volunteer profile.  A super_admin must approve new
-- accounts before they gain elevated permissions.

CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    firebase_uid    TEXT UNIQUE NOT NULL,
    email           TEXT UNIQUE NOT NULL,
    display_name    TEXT,
    photo_url       TEXT,
    volunteer_id    INTEGER REFERENCES volunteers(id) UNIQUE,
    role            TEXT NOT NULL DEFAULT 'pending'
                        CHECK (role IN ('pending', 'volunteer', 'admin', 'super_admin')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    last_login_at   TIMESTAMPTZ
);
