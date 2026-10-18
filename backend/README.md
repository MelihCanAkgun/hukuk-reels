# Private two-player Block Blast service

Live API: https://hukuk-games-social.hukuk-games-social.workers.dev

Cloudflare Workers + D1 on the Free plan. No paid plan, domain, queue, or third-party push provider is required. GitHub Pages remains the frontend host. Web Push uses the browser vendors' gateways directly. Free quotas are enforced by the provider; do not enable a paid plan without the owner's permission.

## Players

Exactly two rows are permitted by the database constraint. Each player has a cryptographically random 256-bit invite code; only its SHA-256 hash is stored in D1. Codes and VAPID private key are in the ignored `.secrets/` directory (mode 0700; files 0600). Never commit/upload that directory to Pages. Give each player only their own code from `.secrets/oyuncu-kodlari.txt`. The code can reconnect the same player on another device. Keep it safely: this small private system has no email recovery.

Open Block Blast → leaderboard icon → enter name and code. Joining imports the device's existing record. Scores are personal bests, not cumulative totals. Ties share rank. Every game has its own leaderboard: Block Blast stays in `players.best`; Flappy Silly Cat, Subway Silly and Adliye Kulesi are rows in `game_scores` (migration `0006_game_scores.sql`), sent as `POST /score {game, score}` and returned by `/board` as `scores: [{id, game, best}]`. Each game notifies the other player once when they are overtaken. The leaderboard icon is in every game's top bar. This is a trust-based game between two friends; client scores are bounded and authenticated but not replay-validated anti-cheat scores.

## Push

Both players must tap “Bildirimleri aç”. iPhone/iPad require iOS 16.4+ and launching the installed Home Screen web app. An existing installation must apply the app update first. Native Flutter runners do not yet have APNs integration; the published PWA is supported.

An atomic SQLite trigger inserts an overtake event only when the submitting player's prior best was <= the opponent's score and their new best is higher. Retried/lower scores do not create duplicate events. Increasing an already-leading score does not notify again. Only Player 1 (admin) can send manual messages; Player 2 is denied server-side (403) and has no composer. Automatic overtake notifications still work in both directions. One manual message per 30 seconds; maximum 180 characters. Messages require an active recipient subscription. A bounded outbox delivers immediately via waitUntil; a five-minute cron retries transient errors up to four attempts, within one hour. Notification tags collapse retries. The admin panel shows the last gateway result separately from queue acknowledgement. Logs contain only event IDs, HTTP status codes and error types, never message contents or device endpoints. The provider's acceptance cannot guarantee display (permissions, Focus and connection matter). Outbox data expires after seven days. No manual notifications are sent during deployment/testing.

Only browser push hosts are accepted as subscription endpoints; requests are authenticated and restricted to the frontend origin. CORS is additional protection, not authentication. Subscription expiry (404/410) removes the invalid device. Up to five devices per player. “Bildirimleri kapat” removes the current device subscription.

## Profile photos

Each registered player may store one profile photo; only the two players (with their own Bearer code) can read them. Photos live in the D1 `avatars` table (migration `0002_avatars.sql`), never in the GitHub Pages bundle or repository.

- `GET /avatar?id=1|2` returns `{id, version, data}` as JSON with `Cache-Control: no-store` and `nosniff`; it is never served with an image/HTML type. `/board` exposes only a 20-hex-digit version tag per player.
- `POST /avatar {data}` accepts a base64 JPEG up to 96 KB and 1024×1024. The server re-checks the JPEG structure and drops APP1–APP15 (EXIF/GPS/XMP/ICC) and comment segments before storing; the client has already re-encoded the photo to a 320 px square through a canvas. Uploads are limited to one per 10 seconds per player.
- `POST /avatar/delete` removes only the caller's own photo.
- The battle-only test identity and inactive players are refused (403). Foreign origins are refused as for every endpoint.
- The browser photo picker (`<input type=file accept=image/*>`) hands over only the photo the user selects; the app never requests photo-library or camera permission.

Deployment: apply the additive migration **before** deploying the Worker (the board query joins `avatars`):

```sh
cd backend
npx wrangler d1 migrations apply hukuk-games-social --remote
npm run deploy
```

## Activity (son görülme)

Profile → **YÖNETİCİ → Aktiflik** shows when each player last used the app and their recent entries (time range, length, device). Only Player 1 sees the row; `GET /activity` answers Player 2 with 404, so the view is not revealed server-side either.

- `web/social.js` sends `POST /seen {open, device}` when the app opens or returns to the foreground (`open: true`) and every two minutes while it stays visible. Hidden pages and devices without a player code send nothing.
- `players.last_seen` is the latest report. `sessions` (migration `0007_activity.sql`) holds entries: an open within 2 minutes of the last report, or a heartbeat within 10 minutes, continues the current session on the same device; otherwise a new one starts.
- `device` is one of `ipad, iphone, android, mac, windows, other` (from the user agent); nothing else about the device is stored. `/activity` lists 30 days; rows older than 90 days are deleted on writes.
- Areas (migration `0008_activity_areas.sql`): Flutter reports the top screen (`home, block, battle, flappy, subway, tower, summaries, questions, beat, profile, countdown, leaderboard`) through `lib/core/services/activity_area.dart`; `social.js` sends it with the next report (an area change is reported after 2 s; hiding the app sends a final `keepalive` report). Each heartbeat, area change or hide adds the elapsed time (at most 150 s) to the previous report's area in `usage` (per Turkey calendar day); an open never adds time, because the app was hidden before it.
- The screen shows live status with the current area, 7/30-day totals, a daily chart, a weekday × hour heat map, time per area and the entries.

## Security notes

- Every endpoint except `/health` requires a player's 256-bit Bearer code; foreign origins are refused. Responses carry `nosniff`, `no-referrer`, `X-Frame-Options: DENY` and a deny-all CSP.
- The old battle-only test code is public in git history, so the test identity is **disabled** unless a `TEST_PLAYER_HASH` secret (SHA-256 hex of a new, private code) is set. Do not set it in production.
- Player names reject control, zero-width and bidirectional override characters (no spoofed or hidden names).
- The web app ships a Content-Security-Policy (`web/index.html`): scripts only from the site itself (plus WebAssembly for CanvasKit), network access only to the site, this Worker (https/wss) and Google's font fallback host. If `SOCIAL_API_URL` changes, update `connect-src` too. There are no inline scripts (`web/pwa.js`), and the app refuses to run inside a foreign frame.

## Development / deployment

- `npm ci && npm test` (Node 22+, tests use SQLite in memory, no real push recipients).
- `npx wrangler login` (owner's account).
- Existing setup: apply new additive migrations with `npx wrangler d1 migrations apply hukuk-games-social --remote`, then `npx wrangler deploy`; preserve D1 and secrets. Do not re-run seed.sql.
- First-time new account only: create D1, update wrangler.jsonc, apply schema.sql, run `node tools/prepare-secrets.mjs`, apply .secrets/seed.sql, deploy, then `npx wrangler secret bulk .secrets/vapid.json`.
- Flutter: `python3 tools/build_web.py --base-href /hukuk-reels/` from repository root. SOCIAL_API_URL can be overridden with `--dart-define=SOCIAL_API_URL=https://...`; default is the live API.
- The generated existing service worker includes push handlers. Do not install a competing service worker or use plain Flutter build for production.
- Client stores a pending maximum locally before sending and retries on reconnect/resume/every 30 seconds while visible. The board refreshes every 20 seconds while open. Local records survive server outages.

## 1v1 Battle

Open Block Blast → **1v1 Battle**. Use the existing private player identity. Create a six-character room, share its code manually, join on the other device and tap **Hazırım** on both. Battle is available in the published web/Home Screen app; native runners currently show an explanatory message instead of a nonworking socket control.

- Each match is one **SQLite Durable Object**, binding `BATTLES`, class `BattleRoom`. The `battle-v1` migration uses `new_sqlite_classes`, compatible with Cloudflare Free. No paid service or D1/player-table migration is introduced.
- `lib/features/game/block_blast_engine.dart` is the single placement/scoring/line-clear engine. `block_battle_core.dart` adds match rules. `tools/build_battle.py` compiles these exact Dart sources into `backend/generated/battle_rules.js`; do not hand-edit generated output. The SHA manifest and native/JS full-match parity test detect stale compilation.
- **Keep `keep_names: true`.** esbuild renaming Dart-generated constructors breaks runtime type checks. Wrangler's existing deploy script automatically runs the Dart build via `build.command`.
- Each player draws the same committed set at the same set index. New version-2 matches reuse the solo constructive generator with a stable integer RNG (seed + index), up to 16 candidate trays and up to 144 search nodes per board/candidate. Both authoritative boards and remaining pieces are evaluated, with denser boards first (identity-independent). At least one current move and full sequential playability are preferred for both boards; three-large-piece and repeated-single rescue trays are discouraged. This is bounded assistance, not guaranteed survival. The first request for an index commits the set; later requests receive a copy even if boards have changed. Shared sets persist in the match snapshot and are pruned once both players consume them. Restored version-1 matches retain their legacy generator. The client only predicts placements and waits for server refill in version 2. Board-out discards the remaining pieces and advances only that player's set index. Score, damage and crossed thresholds survive a reset; combo/miss state resets.
- Every 500 cumulative score deals one HP damage (5 starting HP); crossed thresholds are processed once, including multiple crossings in one move. Score-threshold damage resolves first. If it ends the match, no later board-out runs. Monotonic per-player move IDs reject gaps and make retries no-ops. IDs and authoritative snapshots persist before broadcast, including after process eviction.
- HTTP room operations use the existing Bearer identity. WebSockets use a 60-second single-use ticket; the invite code is never put in a URL. A replacement socket invalidates the old session without creating another player.
- Only completed placements, ready/resign and occasional reconnect travel over the socket. Five-second auto ping/pong uses hibernation without per-frame traffic. A close starts a 15-second grace period. A silent network is detected after 10 seconds without heartbeat, then gets the same grace. Neither side can place while a player is disconnected.
- Results include winner, final score/lives, board-out count, damage and duration. They remain in the match snapshot for 10 minutes, ready for future statistics integration. Battle never uploads to the single-player leaderboard. Unstarted rooms expire after an hour; active games have no artificial time limit.
- Browser refresh restores the saved room automatically. Unacknowledged moves survive refresh and retry with the same ID. A second tab for the same player replaces the first; the old tab stops reconnecting.

### Battle validation and deployment

From repository root (Flutter/Dart SDK and the existing backend Node dependencies required):

```sh
python3 tools/build_battle.py
flutter analyze
flutter test test/block_battle_core_test.dart test/block_battle_widget_test.dart test/block_blast_engine_test.dart test/block_celebration_test.dart test/widget_test.dart
node --test backend/test/*.test.js test/web_runtime_test.cjs
```

The network test uses two actual local workerd WebSockets and fake identities. No real push message is sent. For optional small-screen rendering: `BATTLE_PREVIEW_PATH=/tmp/block-battle.png flutter test test/block_battle_widget_test.dart --plain-name 'Battle keeps shared board and opponent preview usable at Size(320.0, 568.0)'`.

Deploy backend with the existing command; the Durable Object migration is applied automatically by Wrangler:

```sh
cd backend
npm run deploy
```

No Cloudflare dashboard setting or new secret is required. Existing VAPID secrets and D1 are preserved. If the provider rejects a Free-plan binding, stop and report that rejection; never upgrade the plan automatically.

Then build the frontend from repository root:

```sh
python3 tools/build_web.py --base-href /hukuk-reels/
```

Publish `build/web/` using the existing `gh-pages` checkout/rsync/commit/push flow, preserving `.github/workflows/pages.yml` and `.nojekyll`. Do not publish backend files or `.secrets`. The workflow deploys the branch to GitHub Pages. Verify the remote branch's build-file hashes and live `deployment.json`, `main.dart.js`, `battle.js`, `social.js`, and `flutter_service_worker.js`. See `CODEX_CONTINUATION.md` for the actual phase checks and latest deployment.

### Generator simulation

`dart run tools/battle_generation_simulation.dart 500 150 --check` compares solo, legacy Battle and shared Battle with the same bounded greedy bot and independent tie RNG. It runs 1,000 player lives per mode, caps each at 150 placements and records full shape counts in `tools/battle_generation_report.json`. Means are capped observations, not uncensored human survival estimates. A stopped opponent's board is cleared to avoid treating a dead, blocked board as an ongoing opponent. This isolates generation (no score attacks), rather than estimating complete match duration.

Deployment order: build/publish the compatible frontend with the existing gh-pages workflow, then `cd backend && npm run deploy`. The latter rebuilds the shared Dart rules automatically. No D1 migration, new binding, WebSocket protocol operation or paid service is added.

Candidate ranking also lightly prefers multiple playable pieces and at least two current placements per piece on both boards, while keeping the bounded fallback. It does not promise a rescue. Old snapshots without `damageStep:500` rebase the processed counter to current score / 500 on restore, without retroactive damage; future 500 crossings apply normally.

## Security model (2026-10)

- Everything except `/health` needs one of the two player codes (43-char random, stored only as SHA-256 in D1; `players.id` is constrained to 1 and 2). The leaderboard and all profile photos are served only to those codes; nothing user-specific is in the public repo or the GitHub Pages bundle.
- Player 1 is the creator/admin (mqcan): only that id can send manual notifications, see delivery status and download full-quality photos. These checks are server-side; the app UI only mirrors them.
- Requests are rate limited per IP (`REQUEST_LIMIT`, 120/min) before any token or database work. A name may not match the other player's name (case, dotted/dotless i, accents, spaces, punctuation and emoji ignored).
- `TEST_PLAYER_HASH` must stay unset in production. Never commit `backend/.secrets/`.
- Note: every GitHub Pages site of the account shares the `melihcanakgun.github.io` origin (and its localStorage). Do not publish untrusted pages under that account while the player code is stored in the app.
