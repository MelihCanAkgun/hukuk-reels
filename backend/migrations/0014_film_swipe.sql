-- Additive migration: "Ortak karar" (film swipe). One player starts a session
-- with a fixed deck (unwatched list items + a few TMDB suggestions); both
-- swipe in their own time. Cards are snapshots so a suggestion that is not in
-- the list can be shown; film_id is filled for list items and for matched
-- suggestions once they are added to the list.
CREATE TABLE IF NOT EXISTS swipe_sessions (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 started_by INTEGER NOT NULL REFERENCES players(id),
 created INTEGER NOT NULL,
 status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'done', 'cancelled')),
 finished INTEGER,
 nudged INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS swipe_cards (
 session_id INTEGER NOT NULL REFERENCES swipe_sessions(id) ON DELETE CASCADE,
 pos INTEGER NOT NULL,
 film_id INTEGER,
 tmdb_id INTEGER NOT NULL,
 suggested INTEGER NOT NULL DEFAULT 0,
 title TEXT NOT NULL,
 original_title TEXT NOT NULL DEFAULT '',
 year INTEGER,
 runtime INTEGER,
 genres TEXT NOT NULL DEFAULT '[]',
 overview TEXT NOT NULL DEFAULT '',
 poster TEXT,
 tmdb_rating REAL,
 imdb_rating REAL,
 show_title TEXT,
 season INTEGER,
 episode INTEGER,
 PRIMARY KEY (session_id, pos)
);
-- vote: 0 pass, 1 like, 2 super like (one per player per session).
CREATE TABLE IF NOT EXISTS swipe_votes (
 session_id INTEGER NOT NULL REFERENCES swipe_sessions(id) ON DELETE CASCADE,
 pos INTEGER NOT NULL,
 player_id INTEGER NOT NULL REFERENCES players(id),
 vote INTEGER NOT NULL CHECK (vote IN (0, 1, 2)),
 PRIMARY KEY (session_id, pos, player_id)
);
