-- Additive migration: shared film watchlist ("Filmler" tab). Film details come
-- from TMDB (poster, Turkish title, rating, TR streaming providers) and OMDb
-- (IMDb rating) through the Worker; the API keys stay in Worker secrets.
CREATE TABLE IF NOT EXISTS films (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 tmdb_id INTEGER NOT NULL UNIQUE,
 imdb_id TEXT,
 title TEXT NOT NULL,
 original_title TEXT NOT NULL DEFAULT '',
 year INTEGER,
 runtime INTEGER,
 genres TEXT NOT NULL DEFAULT '[]',
 overview TEXT NOT NULL DEFAULT '',
 poster TEXT,
 tmdb_rating REAL,
 imdb_rating REAL,
 providers TEXT NOT NULL DEFAULT '[]',
 added_by INTEGER NOT NULL REFERENCES players(id),
 added INTEGER NOT NULL,
 watched INTEGER,
 watched_by INTEGER REFERENCES players(id),
 -- The "izlendi" notification goes out once per film (undo/redo loops stay quiet).
 watch_notified INTEGER NOT NULL DEFAULT 0,
 info_updated INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS films_added ON films(added_by, added);
CREATE TABLE IF NOT EXISTS film_ratings (
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 player_id INTEGER NOT NULL REFERENCES players(id),
 hearts INTEGER NOT NULL CHECK (hearts BETWEEN 1 AND 5),
 comment TEXT NOT NULL DEFAULT '',
 updated INTEGER NOT NULL,
 PRIMARY KEY (film_id, player_id)
);
-- "… watchlist'e bir film ekledi!" is sent at once; further additions within
-- ten minutes are collected into one delayed notification ("2 film daha").
CREATE TABLE IF NOT EXISTS film_digest (
 player_id INTEGER PRIMARY KEY REFERENCES players(id),
 notified INTEGER NOT NULL,
 last_film INTEGER NOT NULL,
 notification_id INTEGER
);
