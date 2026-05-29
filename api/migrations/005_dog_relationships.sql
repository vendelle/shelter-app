-- Migration 005: Dog-to-dog relationships
-- Tracks compatibility between dogs for walk planning.
-- Levels: yard, contact_good, contact_caution, parallel_good, parallel_caution, incompatible
-- Canonical ordering: dog_id_1 < dog_id_2 to prevent duplicate pairs.

CREATE TABLE IF NOT EXISTS dog_relationships (
  id SERIAL PRIMARY KEY,
  dog_id_1 INTEGER NOT NULL REFERENCES dogs(id),
  dog_id_2 INTEGER NOT NULL REFERENCES dogs(id),
  level TEXT NOT NULL CHECK (level IN ('yard', 'contact_good', 'contact_caution', 'parallel_good', 'parallel_caution', 'incompatible')),
  notes TEXT,
  UNIQUE(dog_id_1, dog_id_2),
  CHECK (dog_id_1 < dog_id_2)
);

-- Indexes for walk-partner lookups (finding dogs that shared a group)
CREATE INDEX IF NOT EXISTS idx_walks_group_lookup
  ON walks(walk_date, group_index)
  WHERE deleted_at IS NULL AND group_index IS NOT NULL AND group_index > 0;

CREATE INDEX IF NOT EXISTS idx_walks_dog_date
  ON walks(dog_id, walk_date DESC)
  WHERE deleted_at IS NULL;
