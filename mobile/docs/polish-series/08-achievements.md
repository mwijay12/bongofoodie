# Polish 8/15 — relevant badges, recorded milestones

## Evidence and decision

Profile previously granted Pwani Explorer and Spice Scholar unconditionally,
called two favorites a chilli achievement, counted any order as completed and
showed unseen descriptions. No reliable menu-exploration or AI-creation event
ledger existed. Removed those claims rather than inventing tracking history.

Three milestones now have explicit EN/SW criteria and capped progress:

| ID / art | EN | SW | Event criterion |
|---|---|---|---|
| first-order | First order | Oda ya kwanza | One signed-in order submission |
| three-orders | Three orders | Oda tatu | Three signed-in order submissions |
| spice-quiz | Spice knowledge | Mjuzi wa viungo | One server-checked correct daily quiz |

These are recognition, NOT coupons, VIP status, chef certification, payment or
proof of delivery. Cancelled orders still count as historical submissions. No
completed/delivered or product-specific achievement is inferred from mutable
order status, favorites, dish name guesses or client AI flags.

## Artwork and presentation

Generated three distinct matching bronze/orange/ivory medallions: one takeaway
bag/check, three bags, and mortar/pestle/leaves/check. Reviewed generated outputs;
no text, food photography or painted transparency was requested. The square cream
background is intentionally opaque, not a transparent food cutout. Optimized to
512-square PNGs (about 944 KB combined) and decoded at 64 logical pixels × DPR.
No image package, permission, remote fetch at runtime or extra animation added.

Responsive content-height rows replace the cramped three-column fixed-aspect grid.
Every card shows title, actual criterion, Earned/Not yet earned (Imepatikana/Bado
haijapatikana), status icon and progress. Locked copy is not faded, so contrast
and meaning do not depend on opacity/color alone. One full semantic label per
card includes criterion/status/progress; decorative art is excluded. Missing-art
fallback remains a neutral badge icon. Existing surrounding motion is unchanged.

## Event ledger justification and ownership

Migration `20261109020000_achievement_events.sql` follows Prompt 7's reward ledger.
A client/cache-only badge would preserve the fabricated cross-account history
problem, hence a small protected ledger is warranted. No new app dependency.

- Clients cannot read/write the raw achievement ledger. Authenticated RPC returns
  only counts for auth.uid(); no caller-supplied user ID. Guest calls are rejected.
- AFTER INSERT on orders records a submission only when the current authenticated
  user matches the row owner. Wrong-owner/unsigned/service inserts do not award.
  Updating status does not create events; duplicate source IDs do not duplicate
  progress, and failed transactions leave no event.
- Correct results inserted through P7's protected quiz path produce one event per
  owned quiz date. Wrong answers/replays do not grant new quiz events.
- Existing P7 server-owned correct quiz rows can be backfilled idempotently. No
  legacy orders, old client-asserted quiz_attempts, favorites or fabricated wins
  are backfilled. Historical submissions before this migration start at zero;
  the profile states that order tracking starts when badges launch.
- Profile uses account-dependent auto-disposed async progress, not the legacy
  cached order/favorite fallback. Guest/demo is explicitly a locked preview,
  even when demo orders exist. Loading has skeletons; errors show Retry rather
  than zero/earned; a zero response is an honest not-yet-earned state. Old counts
  are hidden during reload/error. No badge progress is persisted locally.
- Confirmed in-app order writes and quiz responses invalidate progress; profile
  also offers Refresh for changes on another device. No live achievement realtime
  subscription, notification, haptic or confetti claim is made.

## Security boundary and deployment

**Migration is not deployed to live Supabase.** Requires the P7 migration first;
missing RPC/network/session errors must stay errors. No production data edited.
General order policies/totals/identity/status authority remain Prompt 11: these
badges describe recorded submissions, not commercially verified valid orders.
They must not be used for financial rewards or access control. Submitted orders
can still be untrusted until checkout hardening; no delivery-count badge ships.

## Validation

Unit/widget tests cover thresholds (0/1/2/3), malformed server counts, locked and
earned art/copy/semantics, full-profile guest preview despite seeded order history,
360×640 / 430×932, EN/SW, light/dark, scale1.3 and reduced motion. PostgreSQL fixture
assertions cover legacy no-backfill, owned insert, wrong-owner denial, update not
counting, rollback, quiz replay, raw-table permissions, account isolation and
unsigned RPC rejection; the CI workflow also replays the migration.

Local PGlite migration/assertions/replay and Dart WASM formatting, spinner/theme/
emoji/diff guards run. Final CI SHA/results recorded on draft PR17. No local Flutter
SDK/app launch, physical-device/screen-reader review, native-speaker sign-off or
real Supabase end-to-end run. No merge/release or food image generation performed.
