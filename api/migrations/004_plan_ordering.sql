-- Migration: Add sort_order to walks for preserving plan ordering
--
-- Run against the DEV database:
--   psql "$DATABASE_URL" -f api/migrations/004_plan_ordering.sql
--
-- Each walk row gets a global position (sort_order) reflecting
-- its position in the plan. This preserves both volunteer order
-- and dog order within volunteers after save + re-fetch.

ALTER TABLE walks ADD COLUMN IF NOT EXISTS sort_order INTEGER;
