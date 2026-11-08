# BongoFoodie — Warm Swahili Luxury

Premium Swahili food delivery for Dar es Salaam: warm, appetising and confident, not corporate. The Flutter app uses Quicksand throughout, with a quiet cream canvas, editorial hierarchy, food imagery, and restrained motion. Design variance 5/10, motion intensity 6/10, visual density 4/10.

## Color

Tokens live in `mobile/lib/core/theme/app_colors.dart`; the light theme is `buildAppTheme()` and existing dark-mode surfaces are retained as semantic tokens. Compatibility names are aliases, not separate palettes.

| Token | Value | Use |
| --- | --- | --- |
| `primary` | #F58220 | Decorative brand orange, icons and glows; not body text |
| `cta` | #DE6208 | Filled actions |
| `primarySoft` | #FDE8D3 | Selected pills and soft highlights |
| `primaryDeep` | #B04A05 | Orange text on cream |
| `cream` | #FAF7F2 | Default light background |
| `surface` | #FFFFFF | Cards and sheets |
| `surfaceWarm` | #F4EEE6 | Chips and quiet surfaces |
| `outline` | #EADFD2 | Separators and outlines |
| `ink` | #2B1B12 | Primary text |
| `inkMuted` | #6F645D | Supporting text |
| `ember` | #1A100B | Dark, editorial accent surfaces |
| `spiceGreen` / `spiceGreenSoft` | #11543A / #DDEFE5 | Green accents and soft backgrounds |
| `gold` | #F2B33D | Ratings and highlights |
| `success` / `danger` | #1F9D55 / #D64545 | Feedback (never use color as the sole signal) |
| `info` | #0284C7 | Informational status |
| `promoOrange` | #F58220 → #E8590C | Warm campaign surface |
| `promoGreen` | #16694A → #0C3F2B | Green campaign surface |
| `darkBackground`, `darkSurface`, `darkCard`, `darkBorder`, `darkTextSecondary` | #18130F, #251E19, #302721, #4A3E35, #D4C5BA | Existing dark-mode hierarchy |
| `navDark`, `heroLight`, `heroMuted`, `darkOrange`, `clear`, `scrim` | #24252A, #FFC98D, #F3B676, #8A3300, transparent, black | Navigation, hero and overlays |

`inkMuted` on cream is approximately 5.37:1 and `primaryDeep` on cream 5.13:1. **Accessibility follow-up:** the requested `cta` with white is approximately 3.59:1 and the bright end of `promoOrange` with white approximately 2.59:1; neither meets 4.5:1 for normal text. The prompt's exact colors are preserved, not represented as AA-compliant. Resolve this with a darker action/surface or dark text, and verify gradient contrast before production. Test dark mode and dynamic text sizes as well.

## Spacing, shape, elevation and motion

`mobile/lib/core/theme/app_tokens.dart` defines spacing `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32, `huge` 48, screen horizontal inset 20, and nav clearance 112. Radii are `sm` 12, `md` 20, `lg` 28, `xl` 36 and `pill` 999. `soft` and `lifted` are the shared shadow recipes. Motion uses 150/280/480ms with ease-out entry, ease-in exit and an optional ease-out-back spring. Honor reduced-motion settings and avoid animation that delays a task.

Use consistent margins, at least 44px touch targets, scalable text and meaningful semantic labels. Prefer theme components and semantic tokens over inline color literals. Larger type and translated text must not be clipped. Remote promotion color fields still exist in the data model; the home UI selects one of the two branded gradients rather than rendering arbitrary remote hex values.

## Guardrail and scope

Run `mobile/scripts/check_theme_colors.sh` to catch explicit hex constructors and the specified Material palette colors outside `core/theme`. This check is intentionally narrow: it cannot detect dynamic colors or decide whether a text/background pair has enough contrast. Theme migration does not resolve the separate navigation positioning, skeleton, product details, image transparency or engagement work. Check onboarding, home, sheets and dark mode on an actual device before release.
