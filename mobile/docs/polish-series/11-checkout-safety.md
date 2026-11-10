# Prompt 11 — checkout safety stage; server lifecycle gate OPEN

## Evidence and scope

At main 43f44c4, CartScreen supplied a dummy TZ phone and guest name, IDs repeated
every 100,000 milliseconds, status started `preparing`, and the repository directly
inserted client `total_price`/items/status into `orders`. Demo confirmation claimed
kitchen preparation. There was no explicit recipient form validation or review.
Live deployment of the earlier reward/achievement migrations is not established;
those do NOT establish a complete general checkout authority contract.

This stage deliberately fails closed rather than shipping apparently live guest
checkout on unverified prices/service area. **Prompt 11 is not complete.** No
schema, live RPC, guest authentication mechanism or production migration was added.

## Implemented

- Empty recipient name/phone inputs; no dummy recipient fallback. Latin-script
  name input-quality check (2–100 characters), TZ mobile normalization of local,
  +255 and 255 formats, and 10–500-character address input floor. These checks do
  not prove identity, phone ownership/reachability or a serviceable address.
- Explicit EN/SW scrollable demo review: recipient, normalized phone, address,
  item/quantity/extras, subtotal/delivery/discount/total, payment choice and notes.
  Back/cancel does not write. Cart/address changes while reviewing abort submission;
  edits must be reviewed again. Repeated taps cannot submit during review/write.
- Random.secure UUIDv4-shaped IDs replace repeating clock codes. Demo begins pending,
  not preparing/paid/delivered. Receipt/dialog/share text labels local simulation,
  no kitchen acceptance or payment confirmation; no till-payment instruction in
  the simulation confirmation. Close does not imply live tracking.
- Confirmation clears ONLY the same cart item-list/total snapshot; newer cart or
  changed owner is retained. Disposed OrdersNotifier can return a completed write
  without setting disposed state. No write timeout or automatic network retry.
- Repository blocks createOrder for configured live (including no initialized
  client), before any local read or remote write. UI disables live submission with
  explicit server-pricing/service-area blocker; signing in is not a workaround.
  Guests can still browse/build cart/enter details. This is an unavailable live
  checkout, NOT a forced-account checkout or an implemented anonymous-order API.
- Demo repository rejects invalid recipient/address/status/total shape. Identical
  same-ID local replay returns its existing order; changed same-ID payload fails.
  This is NOT transaction-safe multi-process/server idempotency. Fresh empty local
  history no longer manufactures sample orders. Existing stored demos are not
  deleted; history ownership/migration remains Prompt 12 work.

## Still blocking live checkout

A deliberate server design/deployment must establish:

1. Real service-area configuration and address verification (map/ward/text/GPS is
   NOT proof of coverage). No guessed Dar bounding box or invented restaurant zone.
2. Catalog-linked item/addon availability/quantity and authoritative prices/fees/
   coupons with server-owned pending/unpaid status; reject changed quotes for review.
3. Optional-account guest ownership: disclose authenticated-anonymous or an audited
   expiring server capability design; never use a guessable order ID as authorization.
4. Durable idempotency key + canonical request hash, transactional same-key replay
   and changed-payload rejection under concurrency. Persist pending request/snapshot
   across restart. No blind retry on unknown write outcomes; owned lookup/reconciliation
   by ID must distinguish confirmed/rejected/unknown before another submission.
5. Ownership/RLS, staff roles and permitted status transitions enforced by DB/server,
   not only mobile checks. App-level gate is NOT protection against direct API calls.
6. General owned history, staff update errors and live read fallback cleanup. Existing
   status-update/read APIs were not hardened in this stage; direct API/RLS review,
   abuse tests, race tests and deployment remain mandatory before live enablement.

No live flag exists to bypass this stage's createOrder gate. Do not remove it until
all server/security/service-area gates and migrations have been reviewed/tested.
Demo retry currently creates a fresh request after a failed local save; it is NOT
claimed durable unknown-outcome reconciliation. SharedPreferences is unencrypted
best-effort local storage, not an atomic order database.

## Validation

Added validator/UUID/local replay tests; no seeded orders; changed-cart confirmation
protection; widget invalid/cancelled/review-mutated/pending/error/success coverage.
Existing EN/SW 360×640 and 430×932 light/dark cart tests use text scale1.3.
Separate CI test compiles with non-secret test-only live dart-defines and confirms
an uninitialized configured-live repository cannot write a demo fallback.

Local WASM formatter, spinner/theme/emoji/diff guards run. Local Flutter/Dart SDK
and app launch unavailable: GitHub Flutter3.29.3 CI supplies analysis/test/APK/web
validation (final status in draft PR19). No physical-device/accessibility/native-
speaker/live database/E2E or real delivery/payment tests. No production deployment,
release or claim of complete Prompt11 authority/idempotency/status enforcement.

## Server quote foundation (undeployed)

`20261109030000_checkout_quote_foundation.sql` follows the reward/achievement
migrations. This is deliberately NOT an order-submit API and is not connected to
mobile checkout. The mobile live gate remains in place.

- Revokes direct order INSERT/UPDATE/DELETE and other mutation privileges from
  PUBLIC/anon/authenticated, and drops the schema's legacy unrestricted insert
  and owner/staff update policies. Owner price/status edits and anonymous forged
  inserts must no longer work after deployment. Existing staff clients that update
  orders directly will also stop working: a reviewed staff transition RPC must
  replace that path BEFORE enabling live operations. Do not restore table writes
  as a workaround. No production migration is applied by this commit/CI.
- Adds server-only `checkout_service_wards`: empty by default; enabled defaults
  false; a nonempty operational evidence note is mandatory. Only trusted operators
  via migration/service role may configure it. It is NOT permission for clients to
  self-declare coverage, not a geographic boundary dataset and not seed demo codes.
  Explicit enabled ward must exist under the supplied district/region in live DB.
  Merely claiming that ward still does NOT verify the recipient's street/GPS or
  actual serviceability; address verification/submission remains an open gate.
- `quote_checkout` requires authenticated server UID and is not granted to anon.
  This is NOT a requirement to create a permanent user account: a future reviewed
  anonymous-auth/capability ownership design must be decided and tested. No session
  is silently created here. No guest submit endpoint or owned lookup is added.
- All basket prices, availability, quantity bounds and linked unique addons use
  the existing strict server basket-pricing function, also for orders without a
  promo. Fee comes from server settings; invalid/missing/nonfinite fee fails.
  Optional campaign eligibility uses quote_reward, not client discounts. Returned
  schema-version/currency/parent-chain/totals are previews, not durable quote IDs,
  reservation/payment/acceptance tokens or a signed price guarantee. No campaign
  redemption or order is created by quote_checkout. No client-supplied price wins.
- Quote reads are nonbinding: catalog/config/campaign may change immediately after
  quoting. Future transactional submission MUST recheck authoritative data and
  require review when monetary/eligibility values change. No current claim of
  concurrency-safe quote reservation, durable idempotency or immutable receipt
  snapshots. The existing helper's reward-prefixed error names are retained.

Database CI extends `rewards-security.yml` AFTER prior reward/achievement/concurrency
checks with isolated geography/legacy-grant fixture, migration, quote/ACL assertions
and migration reapplication. Tests include empty/disabled/wrong-parent area, client
price/addon tampering, duplicate/unlinked addons, quantity limits/unavailable item,
nonfinite fee, catalog price changes, reward nonconsumption, direct owner/anon
mutation denial and private config denial. Test codes/coverage are fictitious,
only in the isolated test DB. This verifies the narrow schema fixture, NOT a full
production Supabase deployment, inherited custom-role grants, unknown security-
definer APIs or existing project policy drift. Deployment must audit those paths
and rerun authorization tests against a staging copy. Rerunning a legacy schema
bootstrap must not regrant insecure writes/policies after this migration.

First database CI run 42804378651 passed at fd03cf6. Expanded final results are
recorded in PR19. No new Flutter code, dependencies, routes or map behavior changed
in this server-foundation pass. Full Prompt11 remains incomplete: recipient/address
verification, guest ownership/RLS review, transactional submit/request hash/durable
replay/owned reconciliation, server status transitions and client integration.
