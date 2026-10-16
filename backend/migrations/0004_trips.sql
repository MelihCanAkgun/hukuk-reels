-- Additive migration: flight countdowns. Only the two players (with their
-- Bearer code) can read or write them.
CREATE TABLE IF NOT EXISTS trips (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 destination TEXT NOT NULL,
 arrival INTEGER NOT NULL,
 created INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS trips_arrival ON trips(arrival);
