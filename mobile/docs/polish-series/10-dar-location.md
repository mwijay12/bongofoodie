# Polish 10/15 — Dar address and explicit foreground location; device gate OPEN

## Evidence, sources and deliberately limited coverage

The old sheet chose the first district/ward, restored IDs across arbitrary data
sources, applied out-of-order async responses, swallowed live errors into demo
lists and mixed landmarks into administrative ward names. The default address was
Kijitonyama even without a user choice. These defaults are removed.

`DarLocationReference` is a PARTIAL reviewed list: five district/council labels,
13 wards and one separate common-place example. IDs are internal compatibility
keys, not NBS/postal/geographic codes. It is not complete Tanzania coverage, a
census dataset or a current delivery-service polygon. Review date: 2026-11-09.

Traceable council sources consulted:

- https://kinondonimc.go.tz/kawe — explicitly identifies Kawe as a Kinondoni ward.
- https://kinondonimc.go.tz/new/mwenge-wa-uhuru-2024-watembelea-miradi-nane-wilaya-ya-kinondoni
  — identifies Kijitonyama among Kinondoni wards (2024 report).
- https://dcc.go.tz/en/list-councilors — identifies Tabata and Kariakoo ward seats
  in the city/Ilala administrative context; app label is Ilala, not "Dar CBD".
- https://temekemc.go.tz/secondary-education — ward/project table explicitly lists
  Kurasini and Temeke. This is not used as a complete Temeke ward register.
- https://www.ubungomc.go.tz/wards — lists Sinza, Ubungo, Kimara, Mbezi and Goba
  among the municipality's wards. Only those existing app entries are retained.
- https://kigambonimc.go.tz/mjimwema — identifies Mjimwema as a ward in Kigamboni.
- https://kigambonimc.go.tz/somangila — identifies Somangila ward.
- https://kigambonimc.go.tz/contact-us — explicitly locates Gezaulole in Somangila
  ward. Removed the incorrect Gezaulole ward entry; it is now a place example,
  never a ward/coded selection. Other unreviewed landmarks are not mapped by guess.

Council pages are point-in-time evidence, not a machine-readable/versioned official
boundary release. Demo reference is centralized; legacy non-Dar seed declarations
are not claimed reviewed and are no longer the picker fallback. Production DB
rows remain operator-authored: no remote geography was edited or migrated.

## Behavior and persistence

- Region/district/ward must be deliberately selected; no first-item/first-ward
  default. Parent changes clear descendants and street/landmark text. Only the
  latest async request may populate children. A stale result cannot switch parents.
- Live lists are network reads with a 10-second timeout. Successful empty stays
  empty; failure has Retry and manual fallback, never fabricated demo geography.
  Configured live without an initialized client also fails instead of seeding.
- Scrollable EN/SW sheet, token spacing, skeleton loading and 48dp actions. No
  arbitrary default address is saved when the hierarchy is incomplete. Structured
  confirmation needs a ward and user street/building/landmark text.
- Manual address is always available, including failed/empty lists or an unlisted
  area. It requires at least 10 trimmed characters as an input-quality floor, NOT
  address validation. No claim of geocoding, administrative verification or delivery
  availability. Coverage must be checked at checkout (Prompt 11).
- Structured selection includes source (demo reference version or Supabase project)
  alongside parent/child IDs and street. Each restored child must exist under its
  fetched parent. Old/cross-source/incomplete selections become manual text rather
  than being silently remapped by coincidental numeric IDs. Manual save removes
  stale structured selection. Formatted address restart/signout revision guards
  remain. No coordinates are collected or persisted.
- The device fix never fills the ward or street, even if out of area.
- SharedPreferences remains best-effort, unencrypted and not a database transaction;
  no crash-proof durability or new all-user-data isolation guarantee is claimed.

## Explicit foreground location and unfinished device gates

`geolocator` 13.0.2 is the narrowly scoped new native dependency. Its tagged source
(`Baseflow/flutter-geolocator`, `geolocator_v13.0.2`, SHA
1a90e4a8ebe14e3ed2eee4f58c46a2ce821ec6e5) was inspected: Dart >=2.15 <4,
Flutter >=2.8; `LocationSettings`, check/request permission, current position and
open app settings exist. It uses federated Android/Apple/web implementations; CI
resolves those transitive packages and builds Android/web. This is not a security
review of every transitive native implementation. No paid/API-key geocoder added.

- Only explicit **Use current location** calls the device adapter. No startup,
  background tracking, position stream, server upload, storage or reverse geocoding.
  Concurrent taps share one acquisition. The fix is sheet-local and discarded on
  close. Coordinate text is not appended to a saved address.
- Handles denied/permanently denied/services-off/timeout/plugin failure, stale and
  invalid fixes, and reported accuracy worse than 100m. Poor accuracy has manual
  fallback/retry, not an automatic ward match. 100m is an input-quality threshold,
  NOT a verified boundary or address guarantee. OS permission UI cannot be forced
  to complete with a timer; acquisition has plugin + wrapper timeouts.
- Good fixes display coordinates + reported accuracy and explicitly ask for an
  address. No ward is selected from a coordinate. A location outside Dar is also
  just an unverified device fix: it cannot authorize service/delivery. Checkout
  serviceability remains a Prompt 11 blocking contract, not a guessed bounding box.
- Permanently denied offers an explicit Open settings action. No automatic
  settings navigation. Browser settings launch may be unsupported; fallback tells
  users to open device settings manually. Web requires secure context and browser
  policy allowing geolocation; failure retains manual entry.
- Post-`flutter create` branding overlay also applies ONLY coarse/fine Android and
  iOS WhenInUse purpose text. No background location permission or background mode.
  Podfile bypass flag avoids Apple Always-location permission support. CI tests
  overlay idempotence and foreground-only declarations. Native runners are
  regenerated/ignored: use `python3 scripts/apply_branding.py` after creation,
  as CI does. Initial iOS purpose text is English; OS localization needs device QA.

**Physical-device permission acceptance remains OPEN.** Android/iOS/web runtime
once/approximate/denied/permanently denied/services off, GPS accuracy, settings
return, TalkBack/VoiceOver and real service-area/geocoding validation are not
claimed verified by mocked tests or Android compilation. No background permission.

## Validation

Unit coverage checks all curated parent links/unique IDs and Gezaulole as place,
not ward. Widget coverage: 360×640 / 430×932, EN/SW, light/dark, scale1.3; failed
catalog still permits explicit manual save/restart, no automatic selection, and
late district response ignored after a new parent. Existing persistence/signout
race tests remain. Final Flutter CI status is recorded in draft PR18.

Local WASM Dart formatting, spinner/theme/emoji guards and diff check run. No local
Flutter SDK/app launch, real Supabase list audit, physical-device GPS/permission,
screen-reader or native-speaker sign-off. Foreground repository tests cover no-startup-request/concurrent taps, permission
denial/permanent denial, services off, plugin error, low accuracy/stale/invalid
fixes and out-of-Dar coordinates remaining non-service-authoritative. Python
native configuration tests also run in CI. No schema change, production migration,
merge, release or claim that outside-area orders are validated.

## Opt-in embedded map and external navigation

User requested a free alternative to embedding Leaflet.js and easy links to common
map apps. Chosen renderer: **flutter_map 8.2.2**, pure Flutter/Dart (no JavaScript
Leaflet/WebView); it is Leaflet-inspired, not an unrelated engine. Tagged source
`fleaflet/flutter_map` v8.2.2 (6b9fc9c8f2be6aa9f4308c0bfe1a484dcb793559)
was inspected for constructor/callback/cache APIs and SDK requirements. Requires
Dart >=3.6 / Flutter >=3.27: app minimum Dart raised to ^3.6.0, compatible with CI
Flutter 3.29.3. Existing older Dart 3.5 installations must upgrade. `latlong2` is a
direct coordinate-model import; `url_launcher` 6.3.1 opens external apps/browser.
These are narrowly map-scoped dependencies, not new routes/backend services.

- Tile requests begin ONLY after Load map. Consent text discloses tile provider
  receiving IP/viewed area and external map providers receiving chosen address or
  coordinates. No automatic GPS or geocoding from map gestures.
- Default background map: HTTPS OpenStreetMap standard tiles. Displayed/clickable
  attribution remains outside the map viewport. Native User-Agent identifies the
  app/project; browsers use browser User-Agent/Referer. Do not strip Referer in web
  deployment headers. Tile cache uses flutter_map built-in HTTP-header-aware disk
  caching on native, browser HTTP cache on web. No offline download, bulk scrape,
  cache-busting headers or prefetch feature; panBuffer is zero.
- OSM data/library availability is NOT unlimited free hosting or a commercial SLA.
  Policy: https://operations.osmfoundation.org/policies/tiles/ . Deployment must
  confirm caching/identification/attribution and expected volume against policy.
  For production capacity choose an appropriate provider/self-hosted service:
  `--dart-define=MAP_TILE_URL=https://.../{z}/{x}/{y}.png`,
  `--dart-define=MAP_ATTRIBUTION=...`,
  `--dart-define=MAP_ATTRIBUTION_URL=https://...`.
  Include required provider attribution (including OSM data credit where applicable)
  and review provider terms. Bundled client URLs/keys are public, never secret keys.
- Map without a good device fix is clearly a Dar reference view, NOT the manually
  typed address geocoded. Device fix is a labelled pin, NOT verified ward/address.
  Pan/zoom never changes the delivery address. Use my entered address instead
  clears the temporary fix to enable address-search links.
- External Google Maps/Apple Maps use HTTPS searches (app or browser depending on
  device). OpenStreetMap works in a browser. Android Other map apps uses geo URI
  and falls back to OpenStreetMap if launching fails; OS decides available handler.
  No guarantee Google Maps is installed or that an OS always shows a chooser.
  Address strings are URI-encoded, coordinates validated, no untrusted launch URL.
- Loading skeletons, a 20-second initial-load timeout and tile error/Retry are
  provided; manual entry and external links remain when tiles fail. No map pin or
  external URL authorizes delivery/serviceability. Android release INTERNET
  permission is included alongside the foreground-location overlay.

Map tests cover URI encoding/invalid coordinates, opt-in/no initial tile request,
failed tiles/Retry, attribution, launcher failures and empty target at 360/430dp,
EN/SW and scale1.3. Mocked tile/launcher tests do NOT validate real external app
handoff, browser popup policies, public tile server availability/terms compliance,
cache persistence on devices, gesture accessibility or visual device map rendering.
Sandbox network allowlist prevents live OSM tile testing; local Flutter absent.
No routing/geocoding/API-key or paid service was added.
