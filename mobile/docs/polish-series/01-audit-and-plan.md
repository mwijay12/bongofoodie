# BongoFoodie polish series — audit and execution prompts

## Scope and baseline

This is the NEW 15-prompt polish series, not the previous numbered series.
Prompt 1 is a source audit and acceptance plan only; no runtime code, schema,
permissions or dependencies are changed by this document.

Audited base: `55cfc4904eb04cc6b63e1c7744b5630deeffc2e2` (PR 16 merge).
Main Flutter CI run `42700734419` completed successfully for this exact commit.
That is inherited validation, not execution of a new device test in this audit.
AGENTS.md, DESIGN.md, pubspec and CI configuration were read.
Flutter CI pins 3.29.3; Dart constraint ^3.5.0; Riverpod ^2.6.1,
go_router ^14.8.1, Supabase Flutter ^2.8.4, shared_preferences ^2.5.2.
These are manifest constraints, not a claim about exact resolved package versions.

## Product contract

- Browse, search and build a cart without creating an account or a demo identity.
- Guest checkout is deliberate: validated customer details and a review step, not
  a silent submission of seeded phone/name/address. Account login remains optional
  for browsing; cross-device history and privileged actions require identity.
- Demo is explicitly labelled and Dar-focused. It must not imply a live kitchen,
  confirmed payment, real delivery or access to another customer's orders.
- Cache is not confirmation. A local snapshot must never turn failed live writes
  into success; distinguish stale data, genuine empty data and connectivity errors.
- Payment selection, order acceptance, payment verification and delivery are
  separate events. Client-supplied prices/statuses are not authority.
- No photo substitutions, fabricated food facts, automatic AI order submissions,
  unsolicited permission prompts or fake notification/printing claims.

## Source findings and ownership

Line references below describe the audited base; use symbols if later edits move them.
P0 = live-release security/correctness blocker; P1 = required functionality;
P2 = presentation/polish. Source findings are not proof of deployed configuration.

| ID | Priority | Evidence at base | Finding / owner prompt |
|---|---|---|---|
| A01 | P1 | `lib/router/app_router.dart:26–34`; `features/onboarding/onboarding_screen.dart:45–58` | Router has no global login redirect, but instant exploration signs in a demo customer. Add a true guest path; do not replace demo roles with real staff credentials. P3 |
| A02 | P0 | `data/repositories/auth_repository.dart:62–113,139–176` | Offline signup creates a demo user, including email-based demo admin selection. Live signup maps a returned user without requiring a session; verify email-confirmation flow. Live role fallback also uses an email list if profile role cannot be read: UI role is not authorization. Verify RLS and remove misleading live privilege assumptions. P3/P11 |
| A03 | P1 | `state/cart_provider.dart:1–181`; `state/settings_provider.dart:48–93`; `data/repositories/location_repository.dart:15–37` | Cart is memory-only. Theme/language/onboarding and a formatted address string already persist. Add durable cart and structured location without duplicating existing preferences. P4 |
| A04 | P1 | `state/menu_provider.dart:6–20`; `data/repositories/menu_repository.dart:52–182,248–297` | Provider memory is not durable catalog cache. Errors/empty live results can become seed data. Genuine live empty must stay empty; add timestamped, scoped snapshots and explicit stale/error states. P4 |
| A05 | P2 | `core/widgets/promo_dish_image.dart:10–22`; `core/theme/app_tokens.dart` (`PromoCardMetrics`); `docs/dish-artwork.md` | Promo image size is shared already. Measure visible food bounds, not just box dimensions. Five canonical cutouts; missing artwork and provisional masks already documented. P5 |
| A06 | P2 | `data/mock/showcase_seed_data.dart:492–562`; `features/home/home_screen.dart:1016–1111` | Discovery/trivia contains English editorial/reward copy. Curated EN/SW pairs need review; avoid unsupported historical/nutrition claims. P6 |
| A07 | P0 | `state/cart_provider.dart:143–167`; `data/repositories/menu_repository.dart:464–507` | KARIBU2000 is accepted independently of active branch promo, trivia win, expiry or redemption history. Trivia writes swallow errors and wins default to 1. A copied code is not an earned/server-validated entitlement. P7 |
| A08 | P1 | `features/profile/profile_screen.dart:123–160` | Two achievements unconditionally unlock; VIP counts all orders while description says completed; favorites are used for a chilli-themed badge. Define relevant event-based unlock rules. P8 |
| A09 | P1 | `data/repositories/menu_repository.dart:146–148,184–217`; `data/mock/showcase_seed_data.dart:393–414` | Empty customization links become default Swahili sides, including beverages deliberately seeded with no addons. Empty must mean none; error must not invent choices. P9 |
| A10 | P1 | `data/mock/showcase_seed_data.dart:564–635`; `core/widgets/tanzania_location_sheet.dart:135`; `data/repositories/location_repository.dart` | Dar districts/wards already exist, but list mixes wards with landmarks in display names and includes other regions. Verify hierarchy and separate common places; seed codes are not asserted official geographic codes. P10 |
| A11 | P0 | `features/cart/cart_screen.dart:30,68–110` | Seeded phone, fallback guest name/address, no customer form validation/review, client total and preparing status; BF ID has only five timestamp digits. Prior double-submit/catch/finally fixes remain useful but are not a complete order protocol. P11 |
| A12 | P0 | `data/repositories/order_repository.dart:79–114,137–151`; `supabase/schema.sql:389–447` | Create propagates live insert errors now, but status update remains local-first with swallowed live errors; read failures/empty may return local seeded history. Supplied SQL permits own-order updates. Audit deployed policies, authoritative pricing, allowed transitions, ownership and idempotency before live release. P11/P12/P14 |
| A13 | P1 | `features/cart/cart_screen.dart:116–217`; `pubspec.yaml` | Text sharing exists, not print support. Tracking action goes to existing profile. Receipt needs stable ID, breakdown, payment state and print/PDF layout. Thermal hardware is a separate protocol/device gate. P12 |
| A14 | P1 | `core/widgets/bongo_glass_nav_bar.dart:92`; `supabase/schema.sql:647–649`; `pubspec.yaml` | Selection haptic exists; notification preference columns are not delivery infrastructure. No mobile notification/camera/location/printing plugin is declared. Test actual foreground/background/terminated delivery, not just schema fields. P13/P14 |
| A15 | P0 | `data/repositories/chef_ai_repository.dart:16–84,116,155`; `features/chef_ai/chef_ai_screen.dart:130–164`; `supabase/functions/chef-ai/index.ts:103–152` | Edge chat gets message/language but no catalog/history; generated specs supply prices/nutrition and can become cart items. No typed authorized app-action dispatcher was found in these paths. Ground catalog and validate actions server-side; generated recipes are proposals, not kitchen availability. P15 |
| A16 | P1 | `.github/workflows/flutter-ci.yml:37–40`; `.github/workflows/showcase-release.yml` | Android/iOS runners are generated during CI, not checked in here. Native icon/permission configuration must survive regeneration. Existing manual release workflow already verifies successful main SHA and attaches a direct APK; reuse it. P2/P13/P14/P15 |

### Already present — preserve, do not rebuild

- Central food resolver, transparent contain artwork, DPR decode/precache, reduced
  motion and skeleton/fade (`core/utils/dish_asset.dart`, `dish_image_cache.dart`).
- Model unit/line totals and CartState effective totals; quantity 1–20; explicit
  remove/5-second undo; pinned checkout, pending guard and retry.
- Confirmed createOrder failures propagate; no write timeout was added.
- EN/SW presentation copy for showcase dish IDs, existing location sheet,
  profile history, favorites, selected payment tiles and themed tokens.
- Tests in `cart_state_test.dart`, `cart_checkout_test.dart`, `dish_*`,
  `home_polish_test.dart` and shell/system-UI tests. Extend, do not erase them.

## Execution protocol for EVERY prompt

Read AGENTS/DESIGN and the relevant skills; state a five-line plan/evidence before
editing. Inventory existing implementation first. Keep changes scoped and use
shared tokens, >=48dp targets, readable contrast and reduced motion.
No unrelated refactors or new packages without a written need. Native services,
authoritative redemption/order changes and durable storage may require narrowly
scoped dependencies or migrations: document compatibility, security tests and
rollback first. Never silently introduce a new production service.

Commit on the Arena-assigned active branch only; push immediately after each
commit and open a draft PR on first push. No automatic merge authorization is
implied by permission to implement the series. A merged branch must not receive
further changes; continue through Arena on its next active branch.

Run formatter, analyzer versus baseline, all tests and spinner/theme/emoji guards.
Exercise 360x640 and 430x932, text scale 1.3, EN/SW, light/dark and reduced motion.
Runtime app/device verification is separate from widget tests and successful
builds. Record exact untested items; do not report disabled services as working.
Release review APKs as direct `.apk` assets using the existing main-CI workflow;
never expose secrets in files or release notes. Do not publish audit-only builds
as if they contain UI changes.

## The 15 implementation prompts and acceptance gates

### 1 — Audit and plan (this document)
Deliver source-backed risk register, demo/live contract, ordered prompts and
validation ledger. No feature changes. Gate: references checked and scope agreed.

### 2 — App icon, splash and brand delivery
Generate one icon concept through a single options audition, obtain user choice,
then derive native sizes/adaptive foreground/background and splash assets.
Keep essential details inside safe zones; no tiny text or food-photo clutter.
Gate: launcher previews at small sizes/light-dark backgrounds, alpha/mask checks,
and generated Android/iOS projects retain custom branding after CI hydration.

### 3 — Guest browsing and honest auth
Add visible EN/SW Continue as guest on onboarding/auth without creating a demo
account. Polish form focus, validation, password visibility, recovery, errors and
email-confirmation state. Account actions must explain why identity is needed.
Gate: fresh install -> browse -> cart with null user; optional login/signup and
signout flows; no demo staff role escalates live privileges; canceled auth retains
cart. Validate live session/confirmation behavior in an appropriate test project.

### 4 — Durable cache and preferences
Persist cart snapshots and structured location safely; scope user data and clear
it appropriately on account changes. Reuse existing language/theme preferences.
Add versioned catalog/offer/discovery cache with TTL, stale indicator and refresh.
Gate: process restart/offline, corrupt/old payload recovery, expiry/refresh,
genuine empty data, signout isolation and no cached payment/write confirmation.

### 5 — Offers and food image polish
Measure current cards and enlarge visible food without hiding titles/actions.
Audit source alpha and food/name relevance. Retain image loading/fade/hero behavior.
No new food generation until a separate food-art direction is approved.
Gate: both phone sizes/modes/languages; no clip/halo/overflow; placeholder is honest
and cache decode keys match rendering. Human check provisional cutout edges.

### 6 — Daily Discovery, trivia and Swahili copy
Create reviewed EN/SW editorial pairs, meaningful daily selection and accessible
content layout. Localize reward states; do not promise eligibility before P7.
Gate: stable daily selection/timezone, matching translations, long content fits,
empty/error/retry states, no unsupported health/historical claims.

### 7 — Authoritative redeem logic
Specify promo rules and redemption ownership before implementation; isolate demo
rewards. Add server validation/atomic redemption for live expiry, limits, minimum
spend, eligibility and concurrent/replayed requests. Revalidate on order creation.
Gate: expired/disabled/wrong user/reuse/concurrent attempts, normalization, totals,
failed order redemption policy and no hardcoded live bypass. Migration required
if current backend lacks the necessary entitlement/transaction model.

### 8 — Relevant achievement badges
Define event-based rules and bilingual names first. Generate relevant badge art
with consistent visual language; no decorative always-unlocked achievements.
Gate: zero-state, exact threshold, completed vs canceled orders, replay-safe
unlocks, account isolation, accessible labels and readable locked states.

### 9 — Product-specific addons
Use explicit links/category rules. None is a valid result; do not infer chilli
for soda. Validate selection IDs/limits/availability/prices at order creation.
Gate: drinks with zero addons; main dishes with valid options; required/optional
bounds; cart variants and receipt totals agree; unavailable selections recover.

### 10 — Dar demo geography and location permission
Verify Dar district/ward hierarchy from traceable sources; separate landmarks and
common places. Preserve manual selection and delivery notes; reset descendants
when parents change. Foreground permission only on Use current location.
Gate: all parent/child links, selected address restart, permission denial/permanent
denial, inaccurate/unavailable GPS and out-of-service-area handling. Do not claim
comprehensive/official location coverage without source evidence.

### 11 — Validated guest checkout and order lifecycle
Require genuine name, TZ phone, serviceable address and explicit order review;
account remains optional unless a disclosed live backend limitation is unresolved.
Use server-authoritative totals/status, collision-resistant IDs and idempotency.
No write timeout/retry of unknown outcomes; reconcile ambiguous writes by ID.
Gate: invalid forms, duplicate/replayed/modified submissions, catalog price change,
addon/coupon validation, authorization, failed/unknown/confirmed results, no cart
loss and allowed status transitions. Demo cannot imply real kitchen acceptance.

### 12 — History, receipts and printing
Show only owned history with real empty/error/stale states. Reorder revalidates
current catalog. Produce bilingual receipt with line/addon/tax-or-fee/discount
breakdown and payment state; implement platform print/PDF using justified support.
Gate: long/multi-page receipt, cancellation/unpaid wording, saved/share output,
reorder unavailable items and cross-account access denial. Thermal printer model
and protocol must be supplied/tested before promising Bluetooth printing.

### 13 — Notifications, haptics and live feedback
Design opt-in status events and delivery pipeline, token/account lifecycle,
foreground/background handlers, deep links and deduplication. Keep demo events
explicit. Extend subtle haptics without making vibration the only feedback.
Gate: real-device foreground/background/terminated states, denied permission,
signout/token rotation, duplicate/out-of-order events, owned-order navigation,
reduced motion/preferences. Infrastructure/provider setup may be an external gate.

### 14 — Camera, scan and secure delivery confirmation
Add just-in-time camera permission for scanning/proof photos; screenshots do not
need camera permission. Validate typed order-bound, expiring, single-use tokens
with authorized rider/customer roles and replay protection; avoid exposed secrets.
Gate: denial/manual fallback, invalid/expired/wrong-order/replayed code, unauthorized
user, duplicate delivery and upload privacy/retention. A scan alone cannot mark
payment or delivery verified; live proof acceptance requires server confirmation.

### 15 — Grounded AI, authorized actions and release hardening
Ground replies in current catalog with explicit unknowns; do not fabricate price,
allergen safety or availability. Add typed, allowlisted actions: catalog search,
cart proposals, owned history, language and theme; destructive/order/redeem actions
require explicit review/confirmation and the same authorized backend as normal UI.
Gate: prompt injection, other-user history, stale prices, fake tool payloads,
permission denial, cancel/confirm, offline fallback and EN/SW intent tests.
Finish full regression/accessibility/device checklist and publish a SHA-linked
review APK directly on Releases. Preserve honest pending-device/service gates;
do not call the app production-ready on builds alone.

## Validation ledger for Prompt 1

- Source inspection performed; no app/runtime code edited.
- Inherited main CI run 42700734419: successful at base 55cfc49.
- Local Flutter/Dart SDK unavailable (`command -v flutter` returned no path).
  No local analyzer, Flutter tests, emulator/web launch or screenshots performed.
- No deployed Supabase/RLS, payment, OAuth, GPS, camera, push or printer tests run.
- No images fetched or generated in this audit. App-icon choice is still pending.
- Local guards and documentation checks: record command results in PR/final report.
