-- What the shelter's public website says about each dog, refreshed nightly
-- and on demand ("Odśwież teraz"). Kept apart from `dogs` on purpose: `dogs`
-- is our own data and is never overwritten from here — the website only
-- informs (e.g. suggests a new kennel for an admin to accept or ignore).
-- Safe to empty at any time; it's rebuilt from the website.
--
-- (006 was used by the unmerged dog-dates branch and is skipped.)

CREATE TABLE IF NOT EXISTS dog_shelter_profiles (
    dog_id            INTEGER PRIMARY KEY REFERENCES dogs(id) ON DELETE CASCADE,
    -- false: the website has no animal with this dog's shelterid
    found             BOOLEAN NOT NULL,
    status            TEXT,           -- "Do adopcji", "Kwarantanna", "Adopcja", …
    photo_url         TEXT,           -- link to the shelter's image; not copied
    breed             TEXT,
    color             TEXT,
    sex               TEXT,
    birth_date        DATE,
    weight_kg         NUMERIC(5, 1),
    neutered          BOOLEAN,
    arrival_date      DATE,
    arrival_reason    TEXT,           -- "miejsce znalezienia", e.g. "zwrot z adopcji"
    departure_date    DATE,
    location          TEXT,           -- as on the website, e.g. "430 R12 (domek)"
    description       TEXT,
    site_modified_at  TIMESTAMPTZ,    -- when the shelter last edited the page
    fetched_at        TIMESTAMPTZ NOT NULL,
    -- An admin chose to ignore this exact website location; the suggestion
    -- comes back if the website changes it again.
    ignored_location  TEXT
);
