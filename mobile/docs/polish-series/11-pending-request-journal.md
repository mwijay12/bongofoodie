# Prompt11 — pending request/reconciliation foundation, NOT live integration

This follows the undeployed server submission foundation merged in PR20.
No UI/provider calls this coordinator yet; `OrderRepository.createOrder` and the
checkout button retain their configured-live safety gate. No migration, anonymous
sign-in, coverage/runtime enablement or payment/status transition is added.

## State and owner/project scope

`PendingCheckoutCoordinator` stores a versioned project/owner/key/request/phase/
response journal using the existing SharedPreferences dependency. A secure random
UUID request key is generated only for an empty owner/project scope. Request JSON
is copied at prepare invocation before async waits; map getters decode fresh
copies, so caller mutation cannot change the saved payload. An existing different
request blocks creation instead of replacing an unresolved request.

Phases:

- **prepared**: acknowledged storage of the immutable request, no submit call yet.
- **unknown**: acknowledged storage BEFORE entering the transport submission. This
  includes the crash window before HTTP is actually sent: conservative uncertainty
  is preferable to inventing another key after restart.
- **confirmed**: server response structure/quote checked and saved locally.
  Pending/unconfirmed server submission is NOT payment/kitchen/delivery acceptance.

Same-process scopes share an async queue even across new coordinator instances.
Concurrent prepare calls reuse one persisted key; queued submit after a confirmed
result returns it without another write. After an ambiguous result, ONLY explicit
submitSaved retries the SAME key/body (server idempotency), not a fresh basket.
There is no automatic retry, automatic sign-in or timeout wrapper on a write.

Lookup has a 10-second READ timeout. Missing/offline/invalid-response lookup retains
the saved state/key; it does not prove a request failed. RPC/response failures stay
unknown conservatively, including errors that a future typed UX may classify as
definitive rejection. There is no delete/reset/abandon API, so this foundation
cannot discard uncertainty or start another basket after confirmation. Confirmed
receipt acknowledgement/archive and safe definitive-rejection/edit UX remain open.

## Isolation and transport

Storage keys encode both project and authenticated owner; record metadata is
checked on restore. Corrupt/unsupported journal blocks preparation; no silent
fallback/reset. Current UID is checked before queued operations and after async
storage/network boundaries. Changed owner blocks outgoing calls or returned data.
Transport project/owner must match coordinator scope. Supabase adapter uses only
the app's configured singleton client/project, validates UID at call boundaries,
and calls submit_checkout/lookup_checkout, never direct order inserts.

These client checks are NOT server authorization and do not resolve every token
race: a future live integration must bind expected owner to server submission
(e.g. an RPC owner precondition), audit token/session changes while SDK obtains
access tokens, and verify auth-provider lifecycle in E2E. A mock currentOwner
callback is not proof of real anonymous-auth/session correctness. Server ownership
is still based on trusted auth.uid(), not locally encoded owner text.

Only strict pending/unconfirmed response version/order-ID/quote and line-count
shape is accepted; malformed or mismatching results remain unknown. This is not a
replacement for server pricing or a complete receipt parser. Response saved locally
is not cryptographically authenticated: SharedPreferences is unencrypted,
best-effort storage, not an fsync/CAS/transactional database, and acknowledgement is
not a crash-proof durability guarantee. It can contain PII and viewed order data.
The server must never trust a local journal as proof of price/payment/ownership.

Storage failure before prepared/unknown acknowledgement prevents a network call.
Failure saving a confirmed response leaves an unknown durable record for lookup.
Session loss preserves old-owner data for that owner, rather than exposing it to a
new user or inventing a guest key. Retention, secure storage, device signout cleanup
and lost anonymous-session recovery require review before collecting real PII.
Same-isolate queues do NOT coordinate other processes/isolates/devices or hostile
local storage edits; server per-owner key equality remains authoritative. No cart
is ever read or cleared by this coordinator. Caller snapshot/receipt application
and duplicate-confirmation UI must be integrated/tested separately.

## Validation and remaining gates

Injected journal/transport tests cover persisted restart, immediate/post-prepare
caller mutation, failures before either preflight save, lost submit response,
missing/offline lookup, same-body explicit retry, confirmed-save failure followed
by lookup without resubmit, concurrent objects, owner/project isolation, session
switch during hydration/response, corrupt record and malformed response.

No new package, UI route, native permission or server deployment. WASM Dart format,
spinner/theme/emoji/diff guards run locally; GitHub Flutter3.29.3 CI supplies analyze,
tests and APK/web build checks (final results in PR21). Local Flutter/Dart app launch,
real Supabase RPC/token race, OS storage crash, physical-device/security/accessibility
QA not performed. No UI changed, so no claim of new visual screen/device validation.

Prompt11 remains incomplete: server expected-owner/token-race contract; actual
anonymous provisioning/CAPTCHA/abuse controls; stronger local durability/privacy;
cart/UI lifecycle with typed rejected/unknown/confirmed and archive/acknowledgement;
real address verification/service area; staff transitions/payment and end-to-end
authorization. Keep live gate closed until reviewed, tested and deployed separately.
