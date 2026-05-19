-- Migration: Add planner metadata (groups + notes)
--
-- Run against the DEV database:
--   psql "$DATABASE_URL" -f api/migrations/001_planner_metadata.sql

-- 1. Add group_index to walks (for color-coded walk groups)
ALTER TABLE walks ADD COLUMN IF NOT EXISTS group_index INTEGER;

-- 2. Volunteer notes per date (e.g. "10-13", "2 dogs only")
CREATE TABLE IF NOT EXISTS day_plan_volunteer_notes (
  id SERIAL PRIMARY KEY,
  plan_date DATE NOT NULL,
  volunteer_id INTEGER NOT NULL REFERENCES volunteers(id),
  note TEXT,
  UNIQUE(plan_date, volunteer_id)
);
