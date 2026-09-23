# Serenity presence and execution analytics

## Meaning
- Active now: estimated unique Roblox accounts with a heartbeat in the last 600 seconds. Rejoins and multiple devices on the same account update one entry. Different accounts held by one person still count separately.
- Executions: successful builds through the shared V3 entrypoint, including reruns. A failed UI build does not count. No backfill before analytics deployment.
- Today/month: calendar periods in Philippine time (UTC+8). All time: since tracking began.
- Dashboard supports 30 daily buckets, 12 monthly buckets and cumulative monthly totals from the beginning. Empty periods show zero.

## Deployment
Cloudflare Worker source: services/active-counter/worker.js. Paste it into the existing serenity-active Worker and Deploy. Keep D1 binding DB -> serenity-presence. Schema additions are CREATE IF NOT EXISTS; existing presence is preserved. Tables and trigger initialize on first API request. Add the Worker secret PRESENCE_HMAC_SECRET with at least 32 cryptographically random characters. Keep it stable and out of GitHub/client code. Missing or short secrets cause API requests to return 503. In Cloudflare: Workers & Pages > serenity-active > Settings > Variables and Secrets > Add > Secret, then Deploy. Add the secret before deploying this Worker code.
Website: https://serenity-active.makimnaritn.workers.dev

## Client
Shared entrypoint dist/ui/serenity-v3.lua creates a fresh random execution UUID for each successful Build, alongside a reusable random session UUID. It sends the Roblox UserId in the X-Serenity-Account header over HTTPS. The header keeps the existing body within the old 128-byte limit; old Workers ignore the header. The execution ID rides in the existing POST /heartbeat and retries with the SAME ID until executionRecorded=true. The previous Worker remains compatible but does not acknowledge analytics; this allows backend rollout after client publication. No extra client request or timer was added for execution history.

A deferred task sends sequential heartbeat requests about every 300 seconds once the Worker acknowledges interval=300 and ttl=600 (120 seconds with the old Worker during rollout). Timeout=10 is a library hint, not a guaranteed native cancellation. Rerun cancels the previous task; runtime destruction cancels it. Minimizing retains presence. Unsupported request functions skip tracking. Set getgenv().SerenityPresenceEnabled=false before execution to opt out. A notice explaining UserId transmission and server-side hashing appears before the first request, once per environment. No username, place, profile or game data is submitted. The Worker computes HMAC-SHA256 with its secret and stores only the account hash and expiry, never the raw UserId. The Worker code does not log identifiers; do not add request-header logging.

## Storage and reliability
account_presence stores the server-generated account hash and expiry. The old presence table is retained but excluded from all counts. execution_events stores random event ID+server-received Philippine date, retained to deduplicate retries. An AFTER INSERT trigger increments execution_days only for a newly inserted event. Duplicate INSERT OR IGNORE does not fire that trigger. A transactional D1 batch updates presence and inserts events atomically. Daily aggregates and analytics start metadata are retained. Events are attributed to their first successful receipt date, including delayed retries.

This stores anonymous execution history, not unique-user history. Public client reports can be spoofed. If a client closes before delivering its event, it can be missed. Rejoining with the same Roblox account does not add an active account. A /leave request is acknowledged without deleting presence so an old session cannot remove a newer session or another device. Accounts leave the count up to ten minutes after their last heartbeat; there is no guaranteed immediate disconnect detection. Only scripts reaching this shared UI entrypoint are covered. Cloudflare logging is separate from application data.

## In-hub card
Both UI adapters display a 66px orange card between the 94px avatar profile and What's new. The heartbeat response now includes the active count, eliminating the client's separate GET /active request. It updates the cached UI count even while minimized; readings older than 360 seconds or failed responses clear to a dash. No animation or per-frame polling is added.

## Cost
Backend history adds database writes/storage per execution and aggregate reads for dashboard refreshes. It does not add client requests. Updated continuously active sessions send approximately 288 heartbeat requests per day, including the active count, plus startup/rerun traffic. The website refreshes every five minutes while visible and on manual refresh/return to the tab. Dashboard/count requests no longer delete database rows; expiry filtering still excludes inactive sessions immediately at query time. Cloudflare plan quotas still apply.

## Checks
Local Lua mocks cover routing, lifecycle, opt-out, rerun cancellation, request errors, identical event retries, explicit acknowledgment and new IDs on reruns. Worker/dashboard JavaScript parses; UUID/body-limit routes tested. SQLite checks cover schema migration, trigger deduplication, daily/month boundaries and all-time aggregation. Cloudflare analytics and visual dashboard validation await manual Worker deployment.

## Five-minute rollout
Deploy the updated services/active-counter/worker.js to the existing Cloudflare Worker; keep DB and existing tables/history. New client code safely stays on 120 seconds until a successful response explicitly advertises interval=300 and ttl=600, then switches automatically without re-execution. Existing old client loops must re-execute Serenity to send the account header. Old clients can still report executions but are excluded from account presence, so migration temporarily undercounts until users reload. The new client does not perform a fallback count GET against the old Worker, so its count displays a dash until backend deployment.

Verified locally: real SQLite-backed Worker tests for combined responses, 600-second expiry, execution retry deduplication, read-only stats, and retained history; mocked Lua tests for both adapter routes, interval negotiation, old-backend compatibility, removal of GET polling, failure/cleanup and rerun behavior. Live Cloudflare deployment is manual.


## Account migration and limitations
Do not add old session totals to account totals: that would count the same users twice. Account presence starts from updated-client reports; execution history and aggregates remain intact. The shared loader URL stays unchanged.

HMAC provides pseudonymization, not account authentication: the public endpoint cannot verify a self-reported Roblox UserId. Do not call this a fraud-proof exact headcount. Keep the secret stable; rotating it produces different hashes and can cause up to ten minutes of overlap. If rotating deliberately, clear only account_presence after rotation to reset the active estimate; do not clear analytics history.

Local regression checks cover twenty repeated rejoins of one account, two distinct accounts, legacy session exclusion, late leave requests, exact expiry, missing secrets, HMAC-only storage, event retry deduplication and retained history. These tests do not replace device testing or deploy Cloudflare.
