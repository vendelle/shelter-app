-- Migration 002: Manage data feature
-- Adds volunteer archiving, role/seniority, and volunteer-dog familiarity

-- Allow archiving volunteers (dogs table already has 'archived')
ALTER TABLE volunteers ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;

-- Volunteer seniority role
-- senior (purple), independent (dark orange), supporter (light orange), new (yellow)
ALTER TABLE volunteers ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'new';

-- Volunteer-dog familiarity relationship
-- Levels: 'good' (green), 'difficult' (yellow), 'never' (red)
-- No entry = unknown/blank (haven't walked yet)
CREATE TABLE IF NOT EXISTS volunteer_dog_familiarity (
  id SERIAL PRIMARY KEY,
  volunteer_id INTEGER NOT NULL REFERENCES volunteers(id),
  dog_id INTEGER NOT NULL REFERENCES dogs(id),
  level TEXT NOT NULL CHECK (level IN ('good', 'difficult', 'never')),
  UNIQUE(volunteer_id, dog_id)
);
