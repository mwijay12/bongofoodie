# Dish artwork status

Canonical files use the existing menu ID, not an English/Swahili display name.
`core/utils/dish_asset.dart` is the registry. Keep the legacy pilau ID stable;
its showcase product is beef pilau, not chicken.

## Available

- menu-chipsi-mayai: existing cutout, reframed to reduce transparent padding.
- menu-nyama-choma: existing cutout, reframed.
- menu-pilau-kuku: existing beef pilau cutout, reframed.
- menu-samaki-kupaka: derived from the existing local fish photograph.
- menu-mishkaki: derived from the existing local skewer photograph.

The fish and skewer exteriors were masked locally with antialiased plate masks;
the skewer mask also retains the wooden handles. No new imagery was generated
or fetched. Originals in assets/images are unchanged. These are provisional
cutouts: a human must review the plate edges and skewer handles over dark and
light backgrounds before release.

## Missing canonical cutouts

menu-wali-nazi, menu-kuku-chapati, menu-ndizi-mzuzu, menu-bongo-burger,
menu-zanzibar-pizza, menu-passion-juice, menu-stoney.

Legacy burger/pizza assets remain usable. The showcase wood-fired pizza is not
the folded Zanzibar street snack; the bilingual display describes it as pizza.
No accurate local photos exist for coconut rice, chicken/chapati, plantains,
passion/mango juice or Stoney. Their misleading showcase image references are
empty until supplied, so the image widget renders a neutral restaurant symbol
rather than fries, fish or an orange icon. Unknown/live products retain their
provided references; no database rows or prices are changed.

The display-only EN/SW copy is keyed to showcase IDs in core/l10n/dish_copy.dart.
It does not rewrite cart snapshots, ingredient/allergen lists or live UUID rows.
