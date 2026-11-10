# Polish 5/15 — food-led offer cards

## Evidence and layout changes

The previous promo image slot was 76 logical pixels inside a 285×220 card.
Canonical art is 1600×1600, so increasing source resolution alone would not fix
its small appearance. New shared geometry: 320×320 card, 148×148 contain image.
Image slot is 1.95× its former linear size; this is geometry, not a device-measured
performance or perceived-size claim.

`PromoOfferCard` separates a badge/title + artwork row from full-width subtitle
and a menu-discovery action. Image never paints underneath copy. Title supports
four lines; subtitle three. Full unsnipped copy is available as one semantic button
label. Whole card remains the tap target and existing category navigation remains.
No new offer eligibility, coupon application, menu ID or pricing rule was added.
CI caught a 9px bottom overflow in the initial 300dp-high candidate at text scale
1.3; the shared real/skeleton height was increased to 320dp without reducing text
scale or image size.

`SkeletonPromoCard` uses the same row, image and card dimensions. Home prewarms
only the first two resolved LOCAL promotion images after a frame, at the same
148×DPR decode key as rendering. Existing signature-dish warming remains unchanged.
No eager whole-menu/network precache, image zoom/crop, white backing, extra circle
or new animation was introduced. Existing image fade/reduced-motion path remains.
A successfully empty offers list collapses instead of leaving an empty carousel;
errors now expose the existing localized Retry UI instead of disappearing.

## Source alpha audit (existing files, unchanged)

ImageMagick `%@` alpha bounds measured against the existing 1600-square PNGs.
These are projected logical bounds under contain scaling, NOT screenshots.

| Artwork | Alpha bounds (px) | Previous visible bounds (dp) | New projected bounds (dp) |
|---|---|---|---|
| Chipsi mayai | 1440×1232 | 68.4×58.5 | 133.2×114.0 |
| Nyama choma | 1227×1440 | 58.3×68.4 | 113.5×133.2 |
| Beef pilau, stable legacy ID | 1440×1125 | 68.4×53.4 | 133.2×104.1 |
| Samaki | 1427×1438 | 67.8×68.3 | 132.0×133.0 |
| Mishkaki | 1438×1155 | 68.3×54.9 | 133.0×106.8 |

Existing offer references remain Nyama Choma, beef pilau and wood-fired pizza.
The pilau's old ID/file alias contains kuku, but existing showcase copy/art is beef;
no live product was relabelled to match it. Wood-fired pizza must not be described
as the folded Zanzibar snack. Missing canonical artwork and provisional fish/skewer
mask review are still listed in `../dish-artwork.md`. No food photos were fetched,
generated, substituted or modified in this prompt. New food art needs separate
art-direction approval rather than silently inventing product photography.

## Contrast and semantics

Orange uses ink text, green uses white, independent of app light/dark theme.
Computed sRGB endpoint contrasts:

- Ink #2B1B12 / orange #F58220: 6.38:1.
- Ink #2B1B12 / orange #E8590C: 4.62:1.
- White / green #16694A: 6.66:1.
- White / green #0C3F2B: 11.92:1.

Remote bgHex only selects one of the curated gradients; it cannot set arbitrary
foreground/background colors. Decorative artwork is excluded from duplicate
screen-reader labels. Complete title, badge, subtitle and action remain in the
semantic button even when arbitrary remote copy exceeds visual line limits.
This is not a claim that all other app surfaces meet AA.

## Validation

`promo_offer_card_test.dart` exercises 360×640 / 430×932, EN/SW-length copy,
light/dark, both campaigns and text scale 1.3 with reduced motion; image/copy
non-overlap, card bounds, contain/no ClipRRect, 148×DPR decode, full semantic label,
tap callback and shared skeleton dimensions. Endpoint contrast has a unit check.
Existing Home long-copy, transparency, skeleton and navigation tests remain.

Local dart_style WASM formatting, spinner/theme/emoji guards and diff check run.
No local Flutter SDK, app launch, physical-device screenshot, screen-reader run,
frame profiling or new live-catalog visual review. CI analyzer/tests/APK/web status
must be recorded separately. Existing food mask edges still require human review.
