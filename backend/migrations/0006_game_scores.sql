-- Additive migration: separate personal bests for the arcade games.
-- Block Blast keeps using players.best (and its score_overtaken trigger).
-- A missing row counts as 0. The other player is notified only when the
-- submitter was not ahead before and is strictly ahead now (like Block Blast).
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
