# Polish 7/15 — reward authority

## Narrow schema justification and rules

The prior client accepted KARIBU2000 even with inactive settings, asserted quiz
correctness, defaulted wins to one and mixed live failures with local state.
A client-only fix cannot enforce cross-device limits or redemption concurrency.
Migration `20261109010000_authoritative_rewards.sql` therefore introduces three
RLS-protected tables, RPCs and an order trigger. No app dependency is added.

Rules implemented (restrictive initial policy, no campaign activated):

- Campaign code is uppercase/trimmed, 1–40 characters. Fixed TZS discount, capped
  at canonical food+addon subtotal, never delivery fee. Positive finite campaign
  amount, explicit minimum subtotal, positive lifetime per-user and global limits.
- Active flag and server-clock half-open [starts_at, expires_at) validity window.
  Minimum spend includes authorized addons, before delivery and discount.
- Signed-in owner required; no guest/demo live redemptions. Optional same-Dar-day
  correct quiz requirement defaults ON. No first-order/category/stacking/payment
  eligibility is implied. One code per order; cancellation does not refund a use.
- Only privileged database operations manage campaigns; no public campaign write
  API/admin UI or automatic legacy settings migration. Operations must review
  commercial rules and configure explicit start/expiry/caps before activation.
- Quiz v1 IDs/answer order match DailyCopy: sorted IDs 1/2/3, answers 1/0/1, 2024
  epoch and Africa/Dar_es_Salaam calendar date. Server checks question ID and answer
  index, never a client `is_correct`. First committed attempt/day is authoritative;
  repeats return that stored result. Catalog changes require coordinated migration.
- Old quiz_attempts and local fabricated wins never grant eligibility. New ledger
  starts empty deliberately. No historical entitlement migration is claimed.

## Apply versus redeem

Live Apply requests `quote_reward` with IDs/quantities/addon IDs. Price, availability,
addon ownership and delivery fee are read server-side. Invented dishes, invalid or
duplicate addons, fractional/out-of-range quantities and changed client snapshots
are rejected. Client quote results are invalidated by basket, owner or fee changes;
a late result cannot restore them. Errors never become local discounts.

Quotes do not reserve or consume anything. A BEFORE INSERT trigger rechecks the
campaign, owner, basket, current fee, expiry, quiz and limits, and requires the
submitted total to match. It writes an immutable redemption ledger in the SAME
transaction, protected by a campaign row lock and a deferred order FK. Rollback or
failed order constraints roll back consumption. Competing orders serialize and
only remaining slots succeed. Discounted-order economic fields cannot be edited
later, including by a customer changing/removing the code. Status changes remain
possible through existing policies. Duplicate order IDs cannot consume twice;
ambiguous request outcome/retry reconciliation is still Prompt 11.

Demo uses separate v3 quiz keys, zero initial wins and one counted attempt/day.
Legacy hardcoded promo fallback is removed; even demo must use active matching
branch settings. Demo order payloads do not send a live promo entitlement. Live
quiz copy never offers an unverified hardcoded redemption code; correct answers
are not a promise of a discount. Guest live quiz is practice without entitlement.

## Important limits and deployment gate

**Not deployed to production Supabase. No live campaign activated.** Deploy/review
the migration before this client: the new order `promo_code` column/RPCs must exist.
Old clients claiming quiz correctness lose write permission. Missing RPC/network or
eligibility failures stay failed, with retry UI; they do not fabricate rewards.
Schema snapshot includes the same migration and is replay-safe for these objects.

This guard protects reward-bearing orders, not ALL checkout writes. Existing
non-promo order insert/update policies and client-supplied totals remain broader
security work for Prompt 11; omitting a promo code does not magically make that
path authoritative. Do NOT launch payments/production ordering on the strength
of reward tests alone. Guest identity/details, general server totals/statuses,
idempotency, AI-created dishes and complete product-specific addon rules remain
separate gates. Discounted AI/custom IDs absent from the live menu fail closed.

## Validation and review

- Local PGlite (PostgreSQL WASM), isolated minimal fixture: migration execution,
  quote-not-consume, altered total, wrong owner, invalid quantity/addon, rollback,
  per-user/global caps, expiry, minimum spend, replay, direct-write denial,
  cross-user ledger RLS and unsigned caller rejection passed. No npm dependency
  was added to the repository; the runner is temporary tooling.
- `rewards-security.yml`: isolated PostgreSQL 17 service runs the SQL assertions
  and two independent psql sessions competing for one global slot. Never run
  `supabase/tests/rewards_fixture.sql` against a production database.
- Flutter tests cover live sync-bypass rejection, inactive demo code, stale
  quantity/owner/fee/remove responses, valid quote and nonfinite/negative/oversized
  quotes, ignoring old wins and preventing demo repeat wins. Existing 360/430,
  EN/SW, light/dark, scale1.3 discovery/cart tests remain in the suite.
- Local formatting and spinner/theme/emoji/diff guards run. Local Flutter SDK,
  emulator, physical phone and real Supabase end-to-end validation unavailable.
  CI status/verified SHA are recorded on draft PR17. No merge/release performed.
