-- Migration 006: Dog arrival/departure dates
--
-- Tracks when a dog arrived at the shelter and when it left (adopted,
-- transferred, deceased, etc.) as real data instead of inferring it from
-- walk history. Both nullable — historical dogs won't have these filled
-- in right away, and there's no UI to edit them yet (API-only for now;
-- the edit UI lands in a follow-up).
--
-- Run against the DEV database:
--   psql "$DATABASE_URL" -f api/migrations/006_dog_dates.sql

ALTER TABLE dogs ADD COLUMN IF NOT EXISTS arrival_date DATE;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS departure_date DATE;
