-- Migration 003: Dog-to-dog relationships
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
