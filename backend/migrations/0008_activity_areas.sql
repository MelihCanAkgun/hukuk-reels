-- Additive migration: which part of the app a session is in, and daily time
-- per area for the admin-only activity view. `day` is the Turkey (UTC+3)
-- calendar day number: floor((unix seconds + 10800) / 86400).
ALTER TABLE sessions ADD COLUMN area TEXT NOT NULL DEFAULT 'other';
CREATE TABLE IF NOT EXISTS usage (
 player_id INTEGER NOT NULL REFERENCES players(id),
 day INTEGER NOT NULL,
 area TEXT NOT NULL,
 seconds INTEGER NOT NULL DEFAULT 0 CHECK (seconds >= 0),
 PRIMARY KEY (player_id, day, area)
);
