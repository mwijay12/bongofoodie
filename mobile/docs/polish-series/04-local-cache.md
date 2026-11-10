# Polish 4/15 — local persistence and public catalog cache

## Implemented contract

- Cart provider enables version-1 SharedPreferences snapshots scoped by user ID
  or guest. Direct CartNotifier construction remains memory-only unless explicitly
  enabled, allowing isolated model tests. `ready` and `flushed` expose restoration
  and queued writes for deterministic tests.
- Persist item snapshots/variants/quantities only. Promo code, discount, delivery
  fee, payment state and order confirmation are never restored as entitlements.
- Guest cart carries into optional login. Signout/account switch clears the previous
  account snapshot and restores an empty/new scoped cart. Edits made during restore
  take precedence. Fee refresh does not overwrite pending restored items.
- Cart uses a skeleton during restoration. Corrupt/unknown-version payloads recover
  empty; negative/nonfinite prices are excluded and quantity is clamped to 1–20.
- Existing language/theme/onboarding keys retained. Hydration now respects edits
  made before loading finishes; completing onboarding cannot be undone by a late read.
- Existing formatted address plus versioned region/district/ward/street selection
  persists. Reopened picker matches saved codes only within fetched parents.
  Personal address/selection is cleared on signout/account switch. No GPS or new
  permission request was introduced; Dar content expansion remains Prompt 10.

## Public catalog snapshots

Menu, categories, active promotions and daily discoveries use network-first reads
in live mode, bounded by a 10-second READ timeout. Successful results, including
empty lists, replace snapshots. Live failures no longer silently become seed data
in these four paths. Demo mode continues using existing demo/local content.

Keys include Supabase project URL and menu filters, not user identity: these are
public catalog data. Version, UTC savedAt and payload are stored. A saved result
is fresh for 15 minutes; older results are labelled out-of-date, and anything over
7 days, future-dated, corrupt or unsupported is rejected. TTL is a freshness label,
not a cache-first policy. First offline load can wait for the bounded network read.
Home/menu show saved/stale notice with Retry refresh. Live recovery replaces the
notice source status. Snapshot writes failing do not discard a successful live read.

Branch delivery settings deliberately have no offline confirmation cache: a failed
live settings read reaches the existing checkout retry/disabled-submit state.
No write timeout, automatic order retry or cached acknowledgement was added.

## Safety and limits

SharedPreferences is best-effort device-local storage, not encrypted secret storage
or a transactional database. No passwords/tokens/payment references are stored by
these new caches. Cart prices/availability remain snapshots; authoritative checkout
revalidation/idempotency is still Prompt 11. A cart disk-write exception retains the
in-memory cart rather than crashing; it does not promise persistence through disk
failure or sudden process termination before queued writes complete.

Favorites, trivia and order-history storage are not migrated by this step; their
existing audit findings remain assigned to subsequent reward/history/security work.
No claims about comprehensive account-data isolation are made for those old paths.

## Tests / verification

`local_persistence_test.dart`: restart with variants/quantity, promo reset, clear,
edit-vs-restore, fee refresh, guest-to-account carry, signout/account switch,
corrupt/version mismatch, snapshot freshness/retention/clock rollback/empty values,
structured location and preference hydration races. Existing auth/cart/UI tests run
in CI. Formatter and local guards are run before pushes.

No local Flutter SDK/device/browser app launch, real offline network transition,
process-kill test, deployed Supabase read or storage-failure injection was performed.
Live cache fallback integration needs device/test-backend review; unit tests do not
claim to validate the deployed catalog. CI results are recorded in the PR.
