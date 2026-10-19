-- Block Blast sezon 2: sıralama sıfırdan başlar (yalnız Block Blast; diğer
-- oyunların game_scores tablosuna dokunulmaz). Sezon 1 rekorları arşivde
-- kalır. Geri almak gerekirse:
--   UPDATE players SET best = (SELECT a.best FROM block_season_archive a
--     WHERE a.season = 1 AND a.player_id = players.id);
-- Worker BLOCK_SEASON = 2 ile birlikte yayınlanır; önce worker, sonra bu
-- migration çalışmalı ki eski istemciler eski rekoru geri yazamasın.
CREATE TABLE IF NOT EXISTS block_season_archive (
 season INTEGER NOT NULL,
 player_id INTEGER NOT NULL REFERENCES players(id),
 best INTEGER NOT NULL,
 archived INTEGER NOT NULL DEFAULT (unixepoch()),
 PRIMARY KEY (season, player_id)
);
INSERT OR IGNORE INTO block_season_archive(season, player_id, best)
 SELECT 1, id, best FROM players;
UPDATE players SET best = 0;
