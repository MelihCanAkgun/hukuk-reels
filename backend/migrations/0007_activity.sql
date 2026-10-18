-- Additive migration: "son görülme" and app sessions, visible only to
-- Player 1 (admin) through GET /activity. A session starts when the app is
-- opened or brought to the foreground and is extended by heartbeats while it
-- stays visible. Rows older than 90 days are deleted on writes.
ALTER TABLE players ADD COLUMN last_seen INTEGER NOT NULL DEFAULT 0;
CREATE TABLE IF NOT EXISTS sessions (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 started INTEGER NOT NULL,
 last INTEGER NOT NULL,
 device TEXT NOT NULL DEFAULT 'other'
);
CREATE INDEX IF NOT EXISTS sessions_player ON sessions(player_id, id);
CREATE INDEX IF NOT EXISTS sessions_last ON sessions(last);
