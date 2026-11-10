# Polish 9/15 — product-specific optional extras

## Evidence and fix

Live menu parsing replaced an empty `menu_customizations` join with the global
Swahili sides list. Detail loading also swallowed read failures and replaced both
empty and unknown products with that list, so a soda could acquire pilipili/ugali.
Those fallbacks are removed. No product type is guessed from names or photos.

- Live product links are authoritative. Empty join = no extras; unknown product
  does not acquire options. Missing/malformed joins or prices are errors, not free
  choices. Live reads retain timeout and expose Retry; configured-live clients
  without a client cannot fall back to demo addons.
- Demo has explicit stable-product lists: chipsi sides; grill sides; rice sides;
  fish/chicken accompaniments; a chilli option for plantain; avocado/chilli/drink
  for burger/pizza. Juice and soda remain empty. Unknown demo IDs return empty.
  Existing individual option IDs/prices remain. The inventory named
  defaultSwahiliSides remains for compatibility but is NEVER used as a fallback.
- Optional binary selection: each linked addon may be selected zero or one time
  per product unit. There are no required groups, extra-addon quantities, exclusive
  alternatives or arbitrary global selection caps in the current schema. Do not
  invent such business rules; adding group limits later requires explicit schema
  and server validation. Maximum selection count is the number of unique options
  linked to that product. Dish quantity remains clamped to 1–20.
- A shared validator rejects empty IDs/names, negative/nonfinite prices and
  conflicting duplicate IDs. Identical duplicate options collapse, so one addon
  cannot be charged twice per unit. Relational menu/detail parsing uses the same
  helper. Detail selection resolves current catalog objects by ID, not old price
  objects, so removed options do not enter the new cart line.
- Add is disabled while option loading/error is unresolved, including stale-error
  AsyncValues. Successful empty permits ordering the plain product and hides the
  optional section. Error is not visually indistinguishable from no options.
  The sticky total remains `(base + sum(selected extras)) × quantity`.
- Cart input rejects malformed addon snapshots and deduplicates identical options.
  Adding the same variant again uses the new explicit product/addon price snapshot
  for the combined quantity instead of silently retaining the old snapshot price.
  Restoring invalid/duplicate persisted addon lines excludes those lines rather
  than charging duplicate extras. Undo retains the removed historical snapshot.

## Boundaries

No schema change, package, route or image added. Existing database seed already
links extras to products, not beverages. This does NOT audit/override every live
operator-authored link: if a shop explicitly links chilli to a drink, that catalog
link needs human correction; the client does not silently rewrite it by name.

Cart checks are defense-in-depth, not authorization. Raw cart APIs/AI/history
snapshots cannot establish live product ownership or trusted price. P7's discounted
basket path already validates addon IDs, product links, duplicate choices and
canonical prices on the server. General non-promo checkout/reorder/AI authority
and cross-device stale-price reconciliation remain Prompts 11/12/15. No claim that
all checkout writes are secure or that cached prices are guaranteed current.

## Validation

- Unit tests: empty versus malformed joins, missing price, soda/juice/unknown IDs,
  distinct grill/burger/plantain lists, all seed options valid/unique, duplicate
  charging, conflicting IDs, nonfinite/negative amounts and repriced merge totals.
- Detail regression: 360×640 and 430×932, EN/SW, light/dark, text scale1.3 and reduced
  motion; soda has no chilli/addon section and adds plain at its base price.
  Failed option fetch disables Add; explicit Retry to successful empty re-enables
  plain ordering. Existing toggle/deselect, per-unit × quantity, selected-ID cart,
  hero/motion/section/skeleton tests remain.
- Local WASM formatting, theme/spinner/emoji guards and diff check run. No local
  Flutter SDK/app launch or physical-device/live Supabase catalog review. Final
  CI SHA and analyzer/tests/APK/web results recorded on draft PR17. No merge/release.
