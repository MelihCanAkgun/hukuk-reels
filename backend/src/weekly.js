// Weekly challenge ("haftalık meydan okuma"). Player 1 (admin) starts each
// round by hand; it lasts seven days from that moment. All four games count:
// the better best of the round wins the game, most games wins the round and
// its trophy. A tie is decided by a coin flip made here (the app only
// animates the result).
//
// Notifications: round started, overtaken in a game, the last four hours, and
// the result when the round ends.
export const WEEK_GAMES = ['block', 'flappy', 'subway', 'tower'];
// Trophy designs cycle round by round; names match the app's badges.
export const TROPHIES = ['Altın Kupa', 'Yıldız Kupası', 'Kalp Kupası', 'Taç Kupası', 'Elmas Kupa', 'Şimşek Kupası',
  'Tokmak Kupası'];
const TITLES = {block: 'Block Blast', flappy: 'Flappy Silly Cat', subway: 'Subway Silly', tower: 'Adliye Kulesi'};
export const ROUND_LENGTH = 7 * 86400;
const REMIND_BEFORE = 4 * 3600;
const HISTORY = 30;

const fail = (message, status = 400) => { throw Object.assign(new Error(message), {status}); };
const nowSec = () => Math.floor(Date.now() / 1000);

async function roundScores(env, id) {
  const {results} = await env.DB.prepare(
    'SELECT player_id AS player, game, best FROM weekly_scores WHERE round_id = ? ORDER BY game, player_id').bind(id).all();
  return results;
}
// Games won by each player: a higher score wins, equal scores go to nobody.
export function standing(scores) {
  const wins = {1: 0, 2: 0};
  const detail = WEEK_GAMES.map(game => {
    const of = id => scores.find(s => s.game === game && s.player === id)?.best ?? 0;
    const s1 = of(1), s2 = of(2);
    if (s1 > s2) wins[1]++;
    else if (s2 > s1) wins[2]++;
    return {game, s1, s2};
  });
  return {wins, detail};
}
const activePlayers = async env =>
  (await env.DB.prepare('SELECT id, name FROM players WHERE active = 1 ORDER BY id').all()).results;
const notify = (env, id, title, body) => env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
  .bind(id, title, body).run();
const openRound = env => env.DB.prepare('SELECT * FROM weekly_rounds WHERE decided IS NULL ORDER BY id DESC LIMIT 1').first();

// Closes a round whose time is up, once, and announces the result. Safe to
// call from every request and cron tick.
export async function finalize(env, now = nowSec(), flip = () => crypto.getRandomValues(new Uint8Array(1))[0] & 1) {
  const round = await openRound(env);
  if (!round || round.ends > now) return;
  const scores = await roundScores(env, round.id);
  const {wins, detail} = standing(scores);
  const played = scores.some(s => s.best > 0);
  const tie = wins[1] === wins[2];
  const winner = !played ? null : tie ? (flip() ? 2 : 1) : wins[1] > wins[2] ? 1 : 2;
  const closed = await env.DB.prepare(`UPDATE weekly_rounds SET winner = ?, wins1 = ?, wins2 = ?, coin = ?, decided = ?, detail = ?
    WHERE id = ? AND decided IS NULL RETURNING id`)
    .bind(winner, wins[1], wins[2], played && tie ? 1 : 0, now, JSON.stringify(detail), round.id).first();
  if (!closed || winner === null) return;
  const players = await activePlayers(env);
  const trophy = TROPHIES[round.trophy];
  const score = `${Math.max(wins[1], wins[2])}-${Math.min(wins[1], wins[2])}`;
  for (const p of players) {
    await notify(env, p.id, 'Meydan okuma bitti! 🏆',
      tie ? `${wins[1]}-${wins[2]} berabere bitti. ${trophy} için yazı tura atıldı, sonucu görmek için aç! 🪙`
        : winner === p.id ? `Turu ${score} kazandın, ${trophy} senin!`
        : `${players.find(x => x.id === winner)?.name ?? 'Diğer oyuncu'} turu ${score} kazandı ve ${trophy} onun oldu. Rövanş yeni turda!`);
  }
}

const resultJson = r => ({id: r.id, start: r.started, end: r.ends, winner: r.winner, wins: {1: r.wins1, 2: r.wins2},
  coin: r.coin === 1, trophy: r.trophy, detail: JSON.parse(r.detail)});

export async function weeklyState(env, me, now = nowSec()) {
  await finalize(env, now);
  const round = await openRound(env);
  const scores = round ? await roundScores(env, round.id) : [];
  const {results: rows} = await env.DB.prepare(
    'SELECT * FROM weekly_rounds WHERE winner IS NOT NULL ORDER BY id DESC LIMIT ?').bind(HISTORY).all();
  const totals = {1: 0, 2: 0};
  for (const r of (await env.DB.prepare(
    'SELECT winner, COUNT(*) AS count FROM weekly_rounds WHERE winner IS NOT NULL GROUP BY winner').all()).results) {
    totals[r.winner] = r.count;
  }
  const count = (await env.DB.prepare('SELECT COUNT(*) AS count FROM weekly_rounds').first()).count;
  // Only the latest result is revealed; older unseen ones stay in the history.
  const last = rows[0] && !rows[0][`seen${me}`] ? rows[0] : null;
  return {now, me, players: await activePlayers(env),
    round: round ? {id: round.id, start: round.started, end: round.ends, trophy: round.trophy, startedBy: round.started_by} : null,
    // Only the admin starts a round; the next trophy is shown while waiting.
    canStart: me === 1 && !round, nextTrophy: count % TROPHIES.length,
    scores, wins: standing(scores).wins, totals, history: rows.map(resultJson), reveal: last ? resultJson(last) : null};
}

const scoreText = (game, score) => `${score}${game === 'tower' ? ' kat' : ''}`;

/** `/weekly` (GET) and `/weekly/*` (POST) for an active, registered player. */
export async function weeklyRoute(env, ctx, player, path, method, data, deliver) {
  if (path === '/weekly' && method === 'GET') return weeklyState(env, player.id);
  if (method !== 'POST') fail('Bulunamadı.', 404);
  const now = nowSec();
  await finalize(env, now);
  const round = await openRound(env);
  if (path === '/weekly/start' || path === '/weekly/cancel') {
    if (player.id !== 1) fail('Meydan okumayı yalnız yönetici başlatabilir.', 403);
    if (path === '/weekly/cancel') {
      if (!round) fail('Süren bir tur yok.', 409);
      await env.DB.prepare('DELETE FROM weekly_scores WHERE round_id = ?').bind(round.id).run();
      await env.DB.prepare('DELETE FROM weekly_rounds WHERE id = ? AND decided IS NULL').bind(round.id).run();
      return weeklyState(env, player.id, now);
    }
    if (round) fail('Zaten süren bir tur var.', 409);
    const count = (await env.DB.prepare('SELECT COUNT(*) AS count FROM weekly_rounds').first()).count;
    const trophy = count % TROPHIES.length;
    await env.DB.prepare('INSERT INTO weekly_rounds(started_by, started, ends, trophy) VALUES (?, ?, ?, ?)')
      .bind(player.id, now, now + ROUND_LENGTH, trophy).run();
    const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    if (other) {
      await notify(env, other.id, `${player.name} meydan okuma başlattı! ⚔️`,
        `7 gün, 4 oyun. Ödül: ${TROPHIES[trophy]}. İlk skoru sen yap!`);
      ctx?.waitUntil(deliver(env));
    }
    return weeklyState(env, player.id, now);
  }
  if (path === '/weekly/score') {
    if (!WEEK_GAMES.includes(data.game)) fail('Geçersiz oyun.');
    if (!Number.isSafeInteger(data.score) || data.score < 0 || data.score > 100000000) fail('Geçersiz skor.');
    // `at`: when the score was made on the device. A score from before the
    // round (or sent after it ended) does not count.
    const at = Number.isSafeInteger(data.at) ? Math.min(data.at, now) : now;
    if (!round || at < round.started) return {...await weeklyState(env, player.id, now), ignored: true};
    const best = async id => (await env.DB.prepare(
      'SELECT best FROM weekly_scores WHERE round_id = ? AND player_id = ? AND game = ?').bind(round.id, id, data.game).first())?.best ?? 0;
    const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    const mine = await best(player.id);
    const theirs = other ? await best(other.id) : 0;
    await env.DB.prepare(`INSERT INTO weekly_scores(round_id, player_id, game, best, updated) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(round_id, player_id, game) DO UPDATE SET best = MAX(best, excluded.best), updated = excluded.updated`)
      .bind(round.id, player.id, data.game, data.score, now).run();
    // Overtaken: they had a score this round, I was not ahead and now I am.
    if (other && theirs > 0 && mine <= theirs && data.score > theirs) {
      // An all-time record already sent "Lider değişti!" a moment ago.
      const recent = await env.DB.prepare(`SELECT id FROM notifications WHERE player_id = ? AND created > ?
        AND title = 'Lider değişti! 🏆'`).bind(other.id, now - 90).first();
      if (!recent) {
        const {wins} = standing(await roundScores(env, round.id));
        await notify(env, other.id, 'Meydan okuma ⚔️', `${player.name} bu turda ${TITLES[data.game]} skorunu geçti: ` +
          `${scoreText(data.game, data.score)}. Durum ${wins[other.id]}-${wins[player.id]}.`);
        ctx?.waitUntil(deliver(env));
      }
    }
    return weeklyState(env, player.id, now);
  }
  if (path === '/weekly/seen') {
    if (!Number.isSafeInteger(data.round)) fail('Geçersiz tur.');
    await env.DB.prepare(`UPDATE weekly_rounds SET seen${player.id === 1 ? 1 : 2} = 1 WHERE id = ?`).bind(data.round).run();
    return weeklyState(env, player.id, now);
  }
  fail('Bulunamadı.', 404);
}

// Cron (every five minutes): announces a finished round and queues the
// "last hours" reminder once.
export async function weeklyTick(env, now = nowSec()) {
  await finalize(env, now);
  const round = await openRound(env);
  if (!round || now < round.ends - REMIND_BEFORE) return;
  const first = await env.DB.prepare('UPDATE weekly_rounds SET reminded = 1 WHERE id = ? AND reminded = 0 RETURNING id')
    .bind(round.id).first();
  if (!first) return;
  const players = await activePlayers(env);
  if (players.length < 2) return;
  const scores = await roundScores(env, round.id);
  const {wins} = standing(scores);
  const trophy = TROPHIES[round.trophy];
  for (const p of players) {
    const mine = wins[p.id], theirs = wins[3 - p.id];
    await notify(env, p.id, 'Meydan okuma: son 4 saat ⏳',
      !scores.some(s => s.best > 0) ? `Bu turda henüz kimse oynamadı. Tek bir oyun ${trophy} kazandırabilir!`
        : mine > theirs ? `${mine}-${theirs} öndesin. ${players.find(x => x.id !== p.id).name} yetişmeden rekorlarını sağlamlaştır!`
        : mine < theirs ? `${mine}-${theirs} geridesin. ${trophy} için son şans!`
        : `Durum ${mine}-${theirs}. ${trophy} kimin olacak?`);
  }
}
