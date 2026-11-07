CREATE TABLE IF NOT EXISTS players (
 id INTEGER PRIMARY KEY CHECK (id IN (1, 2)),
 token_hash TEXT NOT NULL UNIQUE,
 name TEXT NOT NULL,
 active INTEGER NOT NULL DEFAULT 0,
 best INTEGER NOT NULL DEFAULT 0 CHECK (best >= 0),
 last_message INTEGER NOT NULL DEFAULT 0,
 last_seen INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS subscriptions (
 endpoint TEXT PRIMARY KEY,
 player_id INTEGER NOT NULL REFERENCES players(id),
 subscription TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS notifications (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 title TEXT NOT NULL,
 body TEXT NOT NULL,
 created INTEGER NOT NULL DEFAULT (unixepoch()),
 attempted INTEGER NOT NULL DEFAULT 0,
 attempts INTEGER NOT NULL DEFAULT 0,
 delivery_status TEXT NOT NULL DEFAULT 'pending',
 sent INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS pending_notifications ON notifications(sent, created);
CREATE TRIGGER IF NOT EXISTS score_overtaken AFTER UPDATE OF best ON players
WHEN NEW.best > OLD.best
BEGIN
 INSERT INTO notifications(player_id, title, body)
 SELECT id, 'Lider değişti! 🏆', NEW.name || ' senin skorunu geçti! Yeni rekor: ' || NEW.best
 FROM players
 WHERE id != NEW.id AND active = 1 AND OLD.best <= best AND NEW.best > best;
END;
CREATE TABLE IF NOT EXISTS avatars (
 player_id INTEGER PRIMARY KEY REFERENCES players(id),
 data TEXT NOT NULL,
 version TEXT NOT NULL,
 updated INTEGER NOT NULL
);
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
CREATE TABLE IF NOT EXISTS trips (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 destination TEXT NOT NULL,
 arrival INTEGER NOT NULL,
 created INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS trips_arrival ON trips(arrival);
CREATE TABLE IF NOT EXISTS notes (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 text TEXT NOT NULL,
 created INTEGER NOT NULL,
 deleted INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS notes_created ON notes(created);
CREATE TABLE IF NOT EXISTS block_season_archive (
 season INTEGER NOT NULL,
 player_id INTEGER NOT NULL REFERENCES players(id),
 best INTEGER NOT NULL,
 archived INTEGER NOT NULL DEFAULT (unixepoch()),
 PRIMARY KEY (season, player_id)
);
CREATE TABLE IF NOT EXISTS game_scores (
 player_id INTEGER NOT NULL REFERENCES players(id),
 game TEXT NOT NULL CHECK (game IN ('flappy', 'subway', 'tower')),
 best INTEGER NOT NULL DEFAULT 0 CHECK (best >= 0),
 PRIMARY KEY (player_id, game)
);
CREATE TRIGGER IF NOT EXISTS game_score_first AFTER INSERT ON game_scores
WHEN NEW.best > 0
BEGIN
 INSERT INTO notifications(player_id, title, body)
 SELECT p.id, 'Lider değişti! 🏆', me.name || ', ' ||
  CASE NEW.game WHEN 'flappy' THEN 'Flappy Silly Cat' WHEN 'subway' THEN 'Subway Silly' ELSE 'Adliye Kulesi' END ||
  ' sıralamasında seni geçti! Yeni rekor: ' || NEW.best || CASE NEW.game WHEN 'tower' THEN ' kat' ELSE '' END
 FROM players p JOIN players me ON me.id = NEW.player_id
 WHERE p.id != NEW.player_id AND p.active = 1
  AND NEW.best > COALESCE((SELECT g.best FROM game_scores g WHERE g.player_id = p.id AND g.game = NEW.game), 0);
END;
CREATE TRIGGER IF NOT EXISTS game_score_overtaken AFTER UPDATE OF best ON game_scores
WHEN NEW.best > OLD.best
BEGIN
 INSERT INTO notifications(player_id, title, body)
 SELECT p.id, 'Lider değişti! 🏆', me.name || ', ' ||
  CASE NEW.game WHEN 'flappy' THEN 'Flappy Silly Cat' WHEN 'subway' THEN 'Subway Silly' ELSE 'Adliye Kulesi' END ||
  ' sıralamasında seni geçti! Yeni rekor: ' || NEW.best || CASE NEW.game WHEN 'tower' THEN ' kat' ELSE '' END
 FROM players p JOIN players me ON me.id = NEW.player_id
 WHERE p.id != NEW.player_id AND p.active = 1
  AND OLD.best <= COALESCE((SELECT g.best FROM game_scores g WHERE g.player_id = p.id AND g.game = NEW.game), 0)
  AND NEW.best > COALESCE((SELECT g.best FROM game_scores g WHERE g.player_id = p.id AND g.game = NEW.game), 0);
END;
CREATE TABLE IF NOT EXISTS sessions (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 player_id INTEGER NOT NULL REFERENCES players(id),
 started INTEGER NOT NULL,
 last INTEGER NOT NULL,
 device TEXT NOT NULL DEFAULT 'other',
 area TEXT NOT NULL DEFAULT 'other'
);
CREATE INDEX IF NOT EXISTS sessions_player ON sessions(player_id, id);
CREATE INDEX IF NOT EXISTS sessions_last ON sessions(last);
CREATE TABLE IF NOT EXISTS usage (
 player_id INTEGER NOT NULL REFERENCES players(id),
 day INTEGER NOT NULL,
 area TEXT NOT NULL,
 seconds INTEGER NOT NULL DEFAULT 0 CHECK (seconds >= 0),
 PRIMARY KEY (player_id, day, area)
);
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
 watch_notified INTEGER NOT NULL DEFAULT 0,
 info_updated INTEGER NOT NULL,
 kind TEXT NOT NULL DEFAULT 'movie',
 show_id INTEGER,
 show_title TEXT,
 season INTEGER,
 episode INTEGER,
 still TEXT
);
CREATE INDEX IF NOT EXISTS films_added ON films(added_by, added);
CREATE UNIQUE INDEX IF NOT EXISTS films_episode ON films(show_id, season, episode) WHERE kind = 'episode';
CREATE TABLE IF NOT EXISTS film_ratings (
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 player_id INTEGER NOT NULL REFERENCES players(id),
 hearts INTEGER NOT NULL CHECK (hearts BETWEEN 1 AND 5),
 comment TEXT NOT NULL DEFAULT '',
 updated INTEGER NOT NULL,
 -- Rating in half hearts (1–10); NULL on old rows means hearts * 2.
 halves INTEGER CHECK (halves BETWEEN 1 AND 10),
 PRIMARY KEY (film_id, player_id)
);
CREATE TABLE IF NOT EXISTS film_replies (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 review_by INTEGER NOT NULL REFERENCES players(id),
 player_id INTEGER NOT NULL REFERENCES players(id),
 text TEXT NOT NULL,
 created INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS film_replies_film ON film_replies(film_id, id);
CREATE TABLE IF NOT EXISTS film_likes (
 film_id INTEGER NOT NULL REFERENCES films(id) ON DELETE CASCADE,
 target TEXT NOT NULL,
 player_id INTEGER NOT NULL REFERENCES players(id),
 liked INTEGER NOT NULL DEFAULT 1,
 created INTEGER NOT NULL,
 PRIMARY KEY (film_id, target, player_id)
);
CREATE TABLE IF NOT EXISTS film_digest (
 player_id INTEGER PRIMARY KEY REFERENCES players(id),
 notified INTEGER NOT NULL,
 last_film INTEGER NOT NULL,
 notification_id INTEGER
);
