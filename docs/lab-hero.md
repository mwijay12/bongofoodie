# Lab ya Ladha — lazy-susan flavour carousel

`web/public/lab/index.html` is a self-contained, framework-free hero for
Bongo Foodie: five Tanzanian dishes ride a wooden lazy-susan, stepping 72°
every 1.9 s while the page colour, ink colour and flavour name crossfade.
It deliberately ships **no** build step and **no** dependencies — plain HTML,
CSS and vanilla JS — so it can also be opened as a single file offline.

Open it at **`/lab/index.html`** (linked from the footer as "Lab ya Ladha").

## Recreating the reference with Bongo Foodie food

The source brief was a fictional gelato brand with five pastel flavours. It is
re-themed rather than re-skinned: the ring is warm acacia wood, the props are
Tanzanian table objects, and each "flavour" is a real dish with its own
background colour.

| # | Dish | Background | Ink | Plate |
| --- | --- | --- | --- | --- |
| 1 | Nyama Choma | `#D2977F` terracotta | `#3E2115` | dark charcoal ceramic |
| 2 | Chipsi Mayai | `#EFC55E` turmeric | `#3E2C06` | cream stoneware |
| 3 | Pilau ya Kuku | `#B9C79D` cardamom leaf | `#26301A` | brass-rimmed |
| 4 | Mishkaki | `#C6A2C0` mauve | `#38203A` | black cast iron |
| 5 | Samaki wa Kupaka | `#A8C9C4` coastal teal | `#123330` | pale terracotta |

All five ink-on-background pairs clear **4.5:1** (measured 5.91 – 8.18:1), so
the wordmark and labels stay readable on every flavour.

## Assets

Everything lives in `web/public/lab/` beside `index.html`.

| File | What it is |
| --- | --- |
| `bowl-*.webp` | 1400 × 1400 plate shots, masked to a circle |
| `ring.webp` | 1024 × 1024 wooden annulus, alpha-cut to the band |
| `props-sheet.webp` | one 1024 × 683 transparent sheet; every prop is a CSS `background-position` crop of it — nothing is sliced into separate files |
| `fonts/` | the same self-hosted Fraunces + DM Sans variable woff2 files the app uses |

The ring's measured geometry (centre `510.5, 511`; outer `501`; inner `291.5`
in a 1024 px image) is stored in the `RING` constant. The band radius
`BAND = 0.791` places bowl centres on the middle of the wood.

Prop crop boxes in `PROPS` were measured from the sheet's alpha channel, so
each box contains exactly one object with no bleed from its neighbour.

## Motion

- One `requestAnimationFrame` loop, `HOLD 1400 ms` + `TURN 500 ms` = 1.9 s per
  step, 9.5 s per full loop.
- The turn uses `cubic-bezier(.42, 0, .58, 1)` solved by Newton iteration in
  `ease()` — the same curve CSS would use, but readable per frame.
- Colour interpolation happens in **linear RGB** (`hexToLinear` → mix →
  `linearToHex`), which avoids the muddy mid-points sRGB mixing produces.
- Bowl positions are a pure function of `p`, so the wrap at 5 → 0 is seamless:
  the hidden bowl crosses the top of the frame where nothing is visible.
- A frame gap over 250 ms (background tab) pushes `phaseStart` forward so the
  loop resumes from a hold instead of jumping.

## Responsive

- Landscape, `W / H ≥ 0.9`: 1440 × 900 design frame, `u = min(W/1440, H/900)`.
  Short landscape (`H < 560`) uses `u = min(W/1440, H/770)` instead, so phones
  on their side crop a little rather than shrinking to illegibility.
- Portrait: 390-wide frame, `u = min(W/390, H/760)`, with the bowl / labels /
  buy button / wordmark stacked and centred.
- Every size is `calc(N * var(--u))`, so the composition scales as one image.

## Accessibility

- `prefers-reduced-motion`: no fade-in, hold 3000 ms, turn 1 ms — the dish and
  colours switch instantly with no rotation.
- Real text for the dish name (not an image), `aria-label` on the menu button,
  `aria-expanded` on the toggle, `alt=""` on the decorative plates.
- Visible `:focus-visible` ring; the buy button is a real link to `/search`.
- Nothing animates a layout property — only `transform` and `opacity`.
