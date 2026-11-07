-- Additive migration: single TV episodes in the shared watchlist (e.g. every
-- Black Mirror episode as its own item). A row is a film (kind 'movie') or one
-- episode (kind 'episode'). Episodes keep the old UNIQUE(tmdb_id) column by
-- storing the TMDB *episode* id negated, so they never collide with film ids;
-- the show/season/episode triple is unique as well.
ALTER TABLE films ADD COLUMN kind TEXT NOT NULL DEFAULT 'movie';
ALTER TABLE films ADD COLUMN show_id INTEGER;
ALTER TABLE films ADD COLUMN show_title TEXT;
ALTER TABLE films ADD COLUMN season INTEGER;
ALTER TABLE films ADD COLUMN episode INTEGER;
ALTER TABLE films ADD COLUMN still TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS films_episode ON films(show_id, season, episode) WHERE kind = 'episode';
