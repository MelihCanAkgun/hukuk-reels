CREATE TABLE IF NOT EXISTS players (
 id INTEGER PRIMARY KEY CHECK (id IN (1, 2)),
 token_hash TEXT NOT NULL UNIQUE,
 name TEXT NOT NULL,
 active INTEGER NOT NULL DEFAULT 0,
 best INTEGER NOT NULL DEFAULT 0 CHECK (best >= 0),
 last_message INTEGER NOT NULL DEFAULT 0
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
