# Polish 2/15 — selected app icon and native splash

The user selected generated option 2: an orange serving bowl with cream steam
on warm charcoal. Source: `assets/brand/app-icon-master.png`, 1024 square.
This is AI-generated brand artwork, not a food/catalog photo. Existing food
assets and in-app logos have not been replaced.

## Assets and installation

- `assets/brand/app-icon-foreground.png`: alpha-isolated bright mark; meaningful
  artwork lies near the central 42% of the square, inside maskable safe bounds.
- `branding/android`: five density legacy launchers, adaptive foreground/background
  plus monochrome alpha, density-aware splash, day/night and Android 12 styles.
- `branding/ios`: opaque icon catalog including 1024 App Store icon, plus transparent
  launch image at 1x/2x/3x. The native storyboard background is charcoal.
- `web/icons`: PWA any/maskable 192/512, Apple touch icon, and favicon. Boot page
  shows the selected icon instead of its old spinner; reduced motion is respected.

CI generates Android/iOS runners using Flutter 3.29.3, then runs:

```sh
# From mobile/, after flutter create --platforms=android,ios,web ...
python3 scripts/apply_branding.py
python3 scripts/test_branding.py
```

The overlay is intentionally outside the generated runners. Re-running flutter
create cannot permanently discard branding as long as the post-create step is
retained. Unexpected launch storyboard structure fails explicitly, not silently.
No launcher/splash Flutter package was added. The scripts do not change IDs,
signing, auth, routes, schema or permissions.

To re-export all sizes from the approved master (requires ImageMagick and Python):

```sh
bash mobile/scripts/generate_branding_assets.sh
```

Background isolation is a brightness-based alpha mask appropriate to this chosen
bright mark/dark background, not a general photo segmentation method. Check edges
if the master changes; do not apply it to food photographs.

## Validation

- PNG dimensions, iOS opaque export, manifest paths and Android XML parse checks.
- Temporary-project overlay, repeated application and simulated regeneration tests.
- Real hydrated-project integration check runs on CI; it is skipped locally when
  native runner directories are absent.
- Source image visually inspected. No physical launcher, Android themed-icon mode,
  Android 12 cold launch, iOS simulator/Xcode build or installed PWA check locally.
- Flutter SDK is absent locally. Remote analyzer/tests/APK/web status must be
  reported separately; successful Android builds do not validate iOS rendering.
- No release APK published from this unmerged branch. Use the verified-main
  showcase release workflow after merge for a direct APK review asset.
