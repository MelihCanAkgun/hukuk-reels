-- Additive migration: half hearts, replies and likes on film reviews.
-- `halves` is the rating in half hearts (1–10). Old rows keep it NULL and read
-- as hearts * 2; `hearts` stays filled (rounded up) for app versions that
-- still read whole hearts.
ALTER TABLE film_ratings ADD COLUMN halves INTEGER CHECK (halves BETWEEN 1 AND 10);
-- A reply answers one player's review (their rating comment) on a film.
CREATE TABLE IF NOT EXISTS film_replies (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 review_by INTEGER NOT NULL REFERENCES players(id),
 player_id INTEGER NOT NULL REFERENCES players(id),
 text TEXT NOT NULL,
 created INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS film_replies_film ON film_replies(film_id, id);
-- target: 'c<player id>' a review, 'r<reply id>' a reply. Unliking keeps the
-- row with liked = 0 so liking again does not notify a second time.
CREATE TABLE IF NOT EXISTS film_likes (
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 target TEXT NOT NULL,
 player_id INTEGER NOT NULL REFERENCES players(id),
 liked INTEGER NOT NULL DEFAULT 1,
 created INTEGER NOT NULL,
 PRIMARY KEY (film_id, target, player_id)
);
