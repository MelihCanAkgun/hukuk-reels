-- Additive migration: private profile photos for the two registered players.
CREATE TABLE IF NOT EXISTS avatars (
 player_id INTEGER PRIMARY KEY REFERENCES players(id),
 data TEXT NOT NULL,
 version TEXT NOT NULL,
 updated INTEGER NOT NULL
);
