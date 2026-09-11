# Private two-player Block Blast service

Live API: https://hukuk-games-social.hukuk-games-social.workers.dev

Cloudflare Workers + D1 on the Free plan. No paid plan, domain, queue, or third-party push provider is required. GitHub Pages remains the frontend host. Web Push uses the browser vendors' gateways directly. Free quotas are enforced by the provider; do not enable a paid plan without the owner's permission.

## Players

Exactly two rows are permitted by the database constraint. Each player has a cryptographically random 256-bit invite code; only its SHA-256 hash is stored in D1. Codes and VAPID private key are in the ignored `.secrets/` directory (mode 0700; files 0600). Never commit/upload that directory to Pages. Give each player only their own code from `.secrets/oyuncu-kodlari.txt`. The code can reconnect the same player on another device. Keep it safely: this small private system has no email recovery.

Open Block Blast → leaderboard icon → enter name and code. Joining imports the device's existing record. Scores are personal bests, not cumulative totals. Ties share rank. This is a trust-based game between two friends; client scores are bounded and authenticated but not replay-validated anti-cheat scores.

## Push

Both players must tap “Bildirimleri aç”. iPhone/iPad require iOS 16.4+ and launching the installed Home Screen web app. An existing installation must apply the app update first. Native Flutter runners do not yet have APNs integration; the published PWA is supported.

An atomic SQLite trigger inserts an overtake event only when the submitting player's prior best was <= the opponent's score and their new best is higher. Retried/lower scores do not create duplicate events. Increasing an already-leading score does not notify again. Only Player 1 (admin) can send manual messages; Player 2 is denied server-side (403) and has no composer. Automatic overtake notifications still work in both directions. One manual message per 30 seconds; maximum 180 characters. Messages require an active recipient subscription. A bounded outbox delivers immediately via waitUntil; a five-minute cron retries transient errors up to four attempts, within one hour. Notification tags collapse retries. The admin panel shows the last gateway result separately from queue acknowledgement. Logs contain only event IDs, HTTP status codes and error types, never message contents or device endpoints. The provider's acceptance cannot guarantee display (permissions, Focus and connection matter). Outbox data expires after seven days. No manual notifications are sent during deployment/testing.

Only browser push hosts are accepted as subscription endpoints; requests are authenticated and restricted to the frontend origin. CORS is additional protection, not authentication. Subscription expiry (404/410) removes the invalid device. Up to five devices per player. “Bildirimleri kapat” removes the current device subscription.

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
- Each player draws the same deterministic set at the same set index; the generator ignores board, score, timing and native Random implementations. Board-out discards the remaining pieces and advances only that player's set index. Score, damage and crossed thresholds survive a reset; combo/miss state resets.
- Score-threshold damage resolves first. If it ends the match, no later board-out runs. Monotonic per-player move IDs reject gaps and make retries no-ops. IDs and authoritative snapshots persist before broadcast, including after process eviction.
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
