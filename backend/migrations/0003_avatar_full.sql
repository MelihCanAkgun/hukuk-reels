-- Additive migration: full-quality profile photos, stored as base64 text parts
-- (D1 values are limited to ~2 MB). `avatars` keeps the small display copy.
CREATE TABLE IF NOT EXISTS avatar_full (
 player_id INTEGER PRIMARY KEY REFERENCES players(id),
 version TEXT NOT NULL,
 size INTEGER NOT NULL,
 width INTEGER NOT NULL,
 height INTEGER NOT NULL,
 parts INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS avatar_full_parts (
 player_id INTEGER NOT NULL REFERENCES players(id),
 version TEXT NOT NULL,
 part INTEGER NOT NULL,
 data TEXT NOT NULL,
 PRIMARY KEY (player_id, version, part)
);
