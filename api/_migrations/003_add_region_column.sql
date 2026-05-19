-- Add optional region override column to dogs table
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS region TEXT;
