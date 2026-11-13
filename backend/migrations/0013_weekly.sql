-- Additive migration: weekly challenge ("haftalık meydan okuma"). Player 1
-- (admin) starts each round by hand; a round lasts seven days. All four games
-- count: the better best of the round wins the game, most games wins the round
-- and its trophy. A tie is decided by a coin flip on the server (coin = 1);
-- the app only animates it.
-- decided NULL: the round is still running. winner NULL after that: nobody
-- played. `detail` keeps the per-game scores ([{game, s1, s2}]) for the
-- history. seen1/seen2: the player has watched the result in the app.
CREATE TABLE IF NOT EXISTS weekly_rounds (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 started_by INTEGER NOT NULL REFERENCES players(id),
 started INTEGER NOT NULL,
 ends INTEGER NOT NULL,
 trophy INTEGER NOT NULL DEFAULT 0,
 winner INTEGER REFERENCES players(id),
 wins1 INTEGER NOT NULL DEFAULT 0,
 wins2 INTEGER NOT NULL DEFAULT 0,
 coin INTEGER NOT NULL DEFAULT 0,
 decided INTEGER,
 detail TEXT NOT NULL DEFAULT '[]',
 seen1 INTEGER NOT NULL DEFAULT 0,
 seen2 INTEGER NOT NULL DEFAULT 0,
 reminded INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS weekly_scores (
 round_id INTEGER NOT NULL REFERENCES weekly_rounds(id) ON DELETE CASCADE,
 player_id INTEGER NOT NULL REFERENCES players(id),
 game TEXT NOT NULL CHECK (game IN ('block', 'flappy', 'subway', 'tower')),
 best INTEGER NOT NULL CHECK (best >= 0),
 updated INTEGER NOT NULL,
 PRIMARY KEY (round_id, player_id, game)
);
