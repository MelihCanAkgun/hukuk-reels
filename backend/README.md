# Private two-player Block Blast service

Live API: https://hukuk-games-social.hukuk-games-social.workers.dev

Cloudflare Workers + D1 on the Free plan. No paid plan, domain, queue, or third-party push provider is required. GitHub Pages remains the frontend host. Web Push uses the browser vendors' gateways directly. Free quotas are enforced by the provider; do not enable a paid plan without the owner's permission.

## Players

Exactly two rows are permitted by the database constraint. Each player has a cryptographically random 256-bit invite code; only its SHA-256 hash is stored in D1. Codes and VAPID private key are in the ignored `.secrets/` directory (mode 0700; files 0600). Never commit/upload that directory to Pages. Give each player only their own code from `.secrets/oyuncu-kodlari.txt`. The code can reconnect the same player on another device. Keep it safely: this small private system has no email recovery.

Open Block Blast → leaderboard icon → enter name and code. Joining imports the device's existing record. Scores are personal bests, not cumulative totals. Ties share rank. This is a trust-based game between two friends; client scores are bounded and authenticated but not replay-validated anti-cheat scores.

## Push

Both players must tap “Bildirimleri aç”. iPhone/iPad require iOS 16.4+ and launching the installed Home Screen web app. An existing installation must apply the app update first. Native Flutter runners do not yet have APNs integration; the published PWA is supported.

An atomic SQLite trigger inserts an overtake event only when the submitting player's prior best was <= the opponent's score and their new best is higher. Retried/lower scores do not create duplicate events. Increasing an already-leading score does not notify again. Only Player 1 (admin) can send manual messages; Player 2 is denied server-side (403) and has no composer. Automatic overtake notifications still work in both directions. One manual message per 30 seconds; maximum 180 characters. Messages require an active recipient subscription. A bounded outbox delivers immediately via waitUntil; a five-minute cron retries transient errors up to four attempts, within one hour. Notification tags collapse retries. The provider's acceptance cannot guarantee display (permissions, Focus and connection matter). Outbox data expires after seven days. No manual notifications are sent during deployment/testing.

Only browser push hosts are accepted as subscription endpoints; requests are authenticated and restricted to the frontend origin. CORS is additional protection, not authentication. Subscription expiry (404/410) removes the invalid device. Up to five devices per player. “Bildirimleri kapat” removes the current device subscription.

## Development / deployment

- `npm ci && npm test` (Node 22+, tests use SQLite in memory, no real push recipients).
- `npx wrangler login` (owner's account).
- Existing setup: `npx wrangler deploy`; preserve D1 and secrets. Do not re-run seed.sql.
- First-time new account only: create D1, update wrangler.jsonc, apply schema.sql, run `node tools/prepare-secrets.mjs`, apply .secrets/seed.sql, deploy, then `npx wrangler secret bulk .secrets/vapid.json`.
- Flutter: `python3 tools/build_web.py --base-href /hukuk-reels/` from repository root. SOCIAL_API_URL can be overridden with `--dart-define=SOCIAL_API_URL=https://...`; default is the live API.
- The generated existing service worker includes push handlers. Do not install a competing service worker or use plain Flutter build for production.
- Client stores a pending maximum locally before sending and retries on reconnect/resume/every 30 seconds while visible. The board refreshes every 20 seconds while open. Local records survive server outages.
