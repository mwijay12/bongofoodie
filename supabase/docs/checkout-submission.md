# Prompt 11 — submission/reconciliation foundation (UNDEPLOYED)

Applies after migrations 010000/020000/030000. Mobile createOrder remains blocked.
This migration does not enable Supabase anonymous sign-ins, configure real service
areas, deploy anything, or make checkout production-ready.

## Server contract

`submit_checkout(p_key uuid, p_request jsonb)` requires a trusted server UID with an
existing profile. Email/password/account permanence is NOT checked or required by
the RPC. A Supabase anonymous authenticated session may qualify if the operator has
reviewed/enabled anonymous auth, profile provisioning, CAPTCHA/rate limits and
recovery policy. Bare anon-key calls have no execution permission. No service-role
key or client-provided owner ID is accepted. Do not expose a privileged proxy that
lets clients spoof auth.uid(). Real anonymous provisioning/abuse/owner RLS staging
verification remains open; the auth fixture only models a trusted UID.

`checkout_runtime.submission_enabled` starts false and has no client grants. No
service area is seeded. Operator runtime and prior service-area configuration are
both required but NOT sufficient for safe launch: selected ward does not establish
actual address deliverability. Keep mobile disabled until address verification,
client integration and status/security gates are complete.

Request v1 (under 64KiB serialized JSON): `version`, catalog `items`, live integer
`region/district/ward`, optional `promo_code`, string `name/phone/address`, supported
`payment_method`, optional string `notes`, and exact `reviewed_quote` from
quote_checkout. Unknown top-level keys are rejected. Phone must already be +255
mobile format; lengths/control-character checks are input-quality rules, not proof
of identity/phone ownership. Client item names/prices are ignored; stored item and
addon IDs/names/prices are server catalog snapshots. No menu AI/custom price path.

The owner's UUID request key and exact JSONB request equality define replay. JSONB
object key order is irrelevant; array order and optional/extra fields are part of
the request. No collision-prone short hash is used as the authorization/fingerprint
check. Future clients must persist and reuse the exact request (not reconstruct a
slightly different basket or review on retry). Changed same-key body is an error.
Reusing the same UUID by a different owner does not authorize access to the first
owner's request. Order IDs are independently server-random and are NOT bearer keys.

Unique key insertion waits on a concurrent same-key transaction, then a row lock
serializes access. Replayed committed response returns BEFORE config/catalog or
campaign revalidation: replay must remain stable after prices/coverage/eligibility
change or submissions are disabled. Failed submissions roll back ledger, order,
reward consumption and achievement events together. No failed/partial request
placeholder is committed as success. Future reconciliation must still handle the
client losing a response even though commit succeeded.

A new submission locks runtime/catalog/config tables in SHARE mode for one DB
transaction (broad deliberately conservative locks; concurrent submissions can
share them, configuration/catalog DML waits). Then it reprices the basket, checks
review equality and snapshots names/prices before inserting pending order. Promo
insert uses existing authoritative reward trigger and achievement ledger in the
same transaction. Pending/unconfirmed response means recorded submission ONLY,
not paid, accepted by kitchen, dispatched or delivered. No payment confirmation
field or status-transition bypass is added. Cancellation/authorized staff status
RPC and immutable post-submit business fields remain open gates.

`lookup_checkout(p_key uuid)` returns only the current owner's committed response,
or NULL. NULL does NOT prove the original operation failed or will never commit:
an in-flight transaction is not visible yet. Never interpret NULL as permission
to create a fresh key. A safe client keeps its durable pending owner/key/body,
reconciles the SAME key, or explicitly resubmits that SAME immutable request.
There is no write timeout/automatic network retry logic in this server SQL.

## Client / deployment gates still OPEN

- Mobile durable pending journal before first write, exact owner/key/body restoration
  after restart and explicit unknown/confirmed/rejected handling; no cart loss.
- Real guest anonymous provisioning, lost-session handling, abuse limits and
  cross-owner auth integration. No fallback to unauthenticated table insert.
- Actual address/service-area verification beyond a supplied ward; privacy/retention
  review. Request body contains PII under server-only grants/RLS. Owner profile
  deletion cascades request journal; existing orders follow base schema deletion
  rules. No production retention/deletion/backup policy is asserted by this work.
- Staff transitions, payment authority, receipt snapshots/history authorization and
  physical-device/live DB/E2E validation. Review all existing privileged functions,
  custom grants and staging schema drift. SQL fixture is not a full Supabase stack.
- Runtime enablement and migration deployment require separate operator review.
  Broad SHARE locks need load/deadlock/lock_timeout/statement_timeout testing for
  production; no throughput/SLA claim. A transaction timeout must never cause a
  client to invent a new request key. DB superuser/service-role remains privileged.

## Validation

`submission_fixture.sql` adds full-schema columns to the isolated rewards fixture;
not deployable. `submission_assertions.sql`: disabled gate, invalid/mutated request,
review mismatch, rollback cleanup, positive authenticated call, same-key replay,
catalog-owned snapshots, stable response after config/price/gate changes, owner
isolation and private journal/runtime/anon permissions. Reapplying migration does
not enable runtime or discard history.

`submission_concurrency.sh`: two PostgreSQL clients submit the same owner/key/body
with a one-use campaign; both succeed with one journal row/order/redemption and one
submission achievement. This tests actual unique-key contention, not mocked Dart.
Existing reward last-redemption concurrency suite also remains. PostgreSQL17 CI is
the verifier; local psql/Docker are unavailable. No new Flutter code/dependencies,
route or UI changes in this pass. Final CI results are recorded in draft PR20.
