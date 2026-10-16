-- Additive migration: cork-board notes. One active note per player for 24 h;
-- deleted notes keep their row (deleted = 1) until expiry so a delete/re-post
-- loop cannot spam notifications.
CREATE TABLE IF NOT EXISTS notes (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 text TEXT NOT NULL,
 created INTEGER NOT NULL,
 deleted INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS notes_created ON notes(created);
