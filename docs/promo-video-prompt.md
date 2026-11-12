# BongoFoodie — Code-to-Video Promo: the prompt

Paste everything below the line into the code-to-video agent. It is written for a
**Remotion**-style agent (React + TypeScript → MP4). If the agent uses Motion
Canvas or Revideo instead, keep the same scenes, timings, copy and assets — only
the API changes.

**Why this version will not get rejected:** the earlier attempt failed with
*"violate our policies about generating prominent people"*. This brief contains
**zero humans** — no faces, no celebrity, no look-alike, no hands. Only food,
app UI, typography, abstract shapes and non-human icons. Do not "helpfully" add
a person, a chef, a customer or a rider to make it feel warmer.

---

## ROLE

You are a senior motion designer and Remotion engineer. Build a 24-second
vertical promo video for **BongoFoodie**, a premium Swahili food-delivery app in
Dar es Salaam, Tanzania. Write real code, render a real MP4, and hand back the
file. Do not return a storyboard, a description, or a placeholder.

## HARD RULES (violating any of these = failed job)

1. **No humans.** No person, face, silhouette of a person, hands, celebrity,
   athlete, politician, influencer, or "person who looks like X". This is a
   hard content-policy constraint, not a style preference. The cast is: food,
   app UI, type, abstract geometry, icons, steam, spice specks.
2. **Do not invent a human mascot or avatar.** The repo's chef character is
   artwork only; leave it out. If you need a "chef" presence, use the app's
   abstract AI/robot icon or a speech bubble with type.
3. **No AI-generated photography.** Use only the supplied real assets. Do not
   call out to an image model, do not generate a new dish image, do not
   "enhance" the food.
4. **Prices, names and copy are data, not flavour text.** Use the exact strings
   in this brief, character for character. Never round, never re-currency,
   never translate a price.
5. **No stock logos.** No Google, Apple, Android, TikTok, Instagram, Visa,
   Mastercard, M-Pesa, Tigo, Airtel or Supabase marks.
6. **Deterministic render.** No `Math.random()`, `Date.now()`, network calls or
   `useEffect`-driven layout at render time. Use Remotion's seeded `random()`
   with a fixed seed, and `staticFile()` for every asset.

## OUTPUT SPEC

| Property | Value |
| --- | --- |
| Primary master | 1080 × 1920, 9:16, 30 fps, 720 frames (24.000 s) |
| Codec | H.264, yuv420p, CRF 18, faststart, no audio stream if music is not licensed |
| Extra renders (same code, `--props`/multi-composition) | 1080 × 1080 (1:1, 720 frames) and 1920 × 1080 (16:9, same cut, safe-area aware) |
| Poster still | PNG at frame 630 (end card), plus frame 300 (dish scene) |
| Colour | sRGB, no HDR |

Design for a phone held vertically: keep all type inside a **safe area of
120 px on each side, 190 px top, 260 px bottom** (story UI + captions).

## BRAND KIT (use these exact values)

```
cream        #FAF7F2   main canvas
surface      #FFFFFF   cards
surfaceWarm  #F4EEE6   chips, quiet blocks
outline      #EADFD2   hairlines, 2px
ink          #2B1B12   primary type
inkMuted     #6F645D   supporting type
ember        #1A100B   dark editorial scene
primary      #F58220   brand orange (decor, not body type)
cta          #DE6208   filled actions
primarySoft  #FDE8D3   selected pills, glow
primaryDeep  #B04A05   orange type on cream
spiceGreen   #11543A   green accent / promo
spiceGreenSoft #DDEFE5 green soft block
gold         #F2B33D   ratings, highlights
promoOrange gradient  #F58220 → #E8590C
promoGreen  gradient   #16694A → #0C3F2B
```

Typeface: **Quicksand** only (Light 300 / Regular 400 / Medium 500 /
SemiBold 600 / Bold 700), from the repo's `mobile/assets/fonts/`. Load it, don't
substitute Poppins or Montserrat. No condensed type, no script, no all-caps
shouting beyond the one promo title.

Type scale at 1080 wide: display 150 px / headline 96 px / subhead 60 px /
body 44 px / caption 32 px / price 72 px. Line-height 1.05 display, 1.35 body.
Letter-spacing −0.02em on display, 0 on body.

Shape: corner radius 28 px on cards, 20 px on chips, pill = fully round.
Shadow: `0 24px 64px rgba(43,27,18,0.14)`, never harsh black.

Motion language: 150 ms micro, 280 ms standard, 480 ms entrances. Enter with
`cubic-bezier(0.22, 1, 0.36, 1)`, exit with `cubic-bezier(0.4, 0, 1, 1)`,
springs for physical objects (dish cards, logo). Nothing bounces twice. Nothing
overshoots more than 8 %.

## ASSETS (download at build time, commit into `public/`, reference via `staticFile()`)

Base: `https://raw.githubusercontent.com/mwijay12/bongofoodie/6db3987/`

| File | Use |
| --- | --- |
| `mobile/assets/dishes/menu-nyama-choma.png` | 1600×1600 transparent cut-out, Nyama Choma & Ugali |
| `mobile/assets/dishes/menu-pilau-kuku.png` | Zanzibar Pilau |
| `mobile/assets/dishes/menu-samaki-kupaka.png` | Samaki wa Kupaka |
| `mobile/assets/dishes/menu-chipsi-mayai.png` | Chipsi Mayai |
| `mobile/assets/dishes/menu-mishkaki.png` | Mishkaki ya Ng'ombe |
| `mobile/assets/brand/app-icon-master.png` | 1024×1024 app icon, orange bowl on ember |
| `assets/readme/hero.png` | wide brand hero, cream, for the 16:9 cut only |
| `mobile/assets/fonts/Quicksand-{Light,Regular,Medium,SemiBold,Bold}.ttf` | typography |

Every dish PNG is a round plate on a transparent background, food filling ~92 %
of the longest edge. **Never crop, recolour, round-mask, or add a plate shadow on
top of the plate.** Float it on cream with a single soft contact shadow at 12 %
opacity, offset 40 px down.

## DATA (exact strings)

```
Dishes
  Nyama Choma & Ugali      TSh 13,500   ★ 4.9  ·  126 reviews  ·  25 min
  Zanzibar Pilau           TSh 10,000   ★ 4.8  ·   97 reviews  ·  20 min
  Samaki wa Kupaka         TSh 15,000   ★ 4.9  ·   73 reviews  ·  25 min
  Chipsi Mayai             TSh  5,500   ★ 4.9  ·   84 reviews  ·  12 min
  Mishkaki ya Ng'ombe      TSh  7,500   ★ 4.7  ·   64 reviews  ·  15 min

Swahili names (use on the second line of a card)
  Nyama Choma na Ugali · Pilau ya Nyama ya Ng'ombe · Samaki wa Kupaka

App
  Tagline SW  Chakula halisi cha Kiswahili kutoka jikoni Kijitonyama hadi mlangoni kwako.
  Tagline EN  Authentic Swahili gastronomy crafted hot in Kijitonyama, Dar es Salaam.
  Greeting    Karibu BongoFoodie
  Feature     Chef Atelier AI — ask for spice pairings or design your own Swahili plate
  Tracker     4 steps: Order placed → Preparing → Ready → Delivered
  Payment     Lipa Namba · Cash on delivery
  Delivery    TSh 2,000 flat in Dar es Salaam

Promo
  Badge       TSh 2,000 OFF
  Title       KARIBU BONGO FEAST
  Sub         Save TSh 2,000 on any Swahili main dish with code KARIBU2000
  Code        KARIBU2000

Links
  Web         bongofoodie.vercel.app
  Repo        github.com/mwijay12/bongofoodie
  Android     Android APK on GitHub Releases
```

Formatting: `TSh` then a **non-breaking space**, then thousands separated by a
comma. Star glyph is a real icon, not the character `★`; set it in `gold`.
Never write "TZS", "$", "TSH" or "Tsh".

## SHOT LIST (frame-exact, 30 fps)

### S0 — Cold open · frames 0–90 (0.0–3.0 s)
Dark, editorial. Background `#1A100B` with a slow radial warm glow behind
centre. Chipsi Mayai cut-out enters from below at 6 % scale-up, rotating 4°
over the shot; a soft steam wisp (two bezier strokes, blur 22 px, 22 % white)
rises and dissipates twice. Camera: 1.00 → 1.08 push-in, ease-out.
Type: nothing. Let the food breathe.
Sound: one crisp sizzle, low sub swell to the cut.

### S1 — Logo lockup · frames 90–210 (3.0–7.0 s)
Whip-pan from ember to `cream` over 8 frames with 12 px directional blur.
App icon springs in at frame 96 (spring: damping 200, mass 0.9, stiffness 120)
from 0.6 scale, landing centre-ish at y ≈ 640, 300 px wide, radius 72 px,
shadow `0 24px 64px rgba(43,27,18,0.18)`.
Wordmark **BongoFoodie** masks up (clip-path reveal bottom→top) at frame 130,
Quicksand Bold 150 px, `ink`, tracking −0.02em, centred, y ≈ 960.
Under it at frame 160, Quicksand Medium 52 px `inkMuted`:
`Karibu` — then at frame 176 the SW tagline fades in, max 3 lines, 52 px/1.35:
`Chakula halisi cha Kiswahili kutoka jikoni Kijitonyama hadi mlangoni kwako.`
Three `surfaceWarm` pills fade in at frames 190/196/202 (stagger 6 frames, 12 px
rise): `Bilingual SW / EN` · `Lipa Namba` · `Dar es Salaam`.

### S2 — Signature dishes · frames 210–378 (7.0–12.6 s)
Cream canvas, headline top-left at 250 px: `Sahani pendwa` Quicksand SemiBold
76 px `ink`, with `Signature dishes` 36 px `inkMuted` beneath.
Three cards, each 1.86 s (56 frames), stacked *scroll* so the previous card
pushes up 18 % and dims to 70 %:

- C1 frames 210–266 — Nyama Choma & Ugali · TSh 13,500
- C2 frames 266–322 — Zanzibar Pilau · TSh 10,000
- C3 frames 322–378 — Samaki wa Kupaka · TSh 15,000

Card spec: 860 × 1080, radius 28, `surface`, shadow soft; dish PNG at 700 px
wide centred in the upper 2/3; name Quicksand SemiBold 56 px `ink` left-aligned
at 56 px padding; Swahili secondary name 34 px `inkMuted`; price 72 px
SemiBold `cta`; rating chip: `gold` star 30 px + `4.9` 34 px `ink` + `· 126`
`inkMuted`; a `primarySoft` pill top-right with the prep time `25 min`.
Entrance: card rises 90 px with spring, content staggers 5 frames apart.
Exit: slide up 60 px + opacity 0 over 12 frames.

### S3 — Chef Atelier AI · frames 378–486 (12.6–16.2 s)
Surface flips to `ember`. Two chat bubbles build, typewriter at 60 chars/s,
left bubble `darkCard` with `ink`… (use `#302721` bubble, `#F4EEE6` text):
`Nini kizuri kwa leo?` then reply bubble in `primarySoft` with `ink`:
`Pilau ya viungo na juisi ya pasheni — karibu.`
At frame 430 a `spiceGreenSoft` pill expands with `spiceGreen` text:
`Buni Sahani · Design your own plate`.
Headline above, Quicksand SemiBold 72 px `#F4EEE6`: `Chef Atelier AI`, and
caption 36 px `#D4C5BA`: `Uliza · Buni · Agiza`. A non-human AI icon (simple
four-dot spark, `primary`) pulses behind at 14 % opacity. No faces, no avatar.

### S4 — From cart to door · frames 486–576 (16.2–19.2 s)
Back to `cream`. Left: receipt-styled card `surface`, 2 px `outline` border,
radius 28: line items `Nyama Choma & Ugali` / `TSh 13,500`, `Uwasilishaji`
(TSh 2,000), hairline, `Jumla Kuu` / `TSh 15,500` in Quicksand Bold 64 px.
Right: a 4-step vertical tracker. Each node is a 48 px circle; completed nodes
fill `spiceGreen` with a white check, the active node is `primary` with a 0 →
100 % progress ring, pending nodes are `outline`. Labels 32 px `inkMuted`:
`Oda imepokelewa` · `Inapikwa` · `Tayari` · `Njiani`.
Nodes light at frames 500, 520, 540, 560 with a 6-frame ring fill and a single
`spiceGreenSoft` ripple. Footer chips fade in at 566: `Lipa Namba`, `Cash`.

### S5 — Promo burst · frames 576–672 (19.2–22.4 s)
Full-bleed `promoGreen` gradient card, radius 40, inset 80 px, sliding in from
the bottom with a spring and a 3° rotation that settles to 0.
`TSh 2,000 OFF` in a `gold` pill (ink type) at frame 592, scale-spring.
`KARIBU BONGO FEAST` Quicksand Bold 92 px `#F4EEE6`, two lines, tracking tight.
Code block: dashed `#DDEFE5` border at 40 % opacity, radius 20, inside
`KARIBU2000` in Quicksand Bold 64 px with `0.18em` tracking, and a caption
24 px `#DDEFE5`: `Tumia kodi hii kwenye oda yako`.
Confetti is banned. Instead, 40 small spice specks (`primarySoft`, `gold`,
`#DDEFE5`) drift up at 8–14 px/frame with seeded positions, 40–90 % opacity.

### S6 — End card · frames 672–720 (22.4–24.0 s)
`cream`. App icon 200 px at y 520, radius 48. Wordmark 88 px `ink`.
`bongofoodie.vercel.app` Quicksand SemiBold 46 px `primaryDeep`.
`github.com/mwijay12/bongofoodie` 34 px `inkMuted`.
A `cta` pill, 640 × 104, radius 999, white type 40 px:
`Pakua app · Get the APK`.
Bottom, 26 px `inkMuted` at 60 %: `Showcase demo · Bei zote ni TSh`.
Last 8 frames: gentle 1.00 → 1.02 push-in and hold (no fade to black, so the
video loops cleanly back into S0).

## TRANSITIONS

One vocabulary only: **12-frame whip with 10–16 px directional blur**, plus a
6-frame dip to the destination background. Frame-accurate cuts at 90, 210, 378,
486, 576, 672. No crossfades longer than 8 frames, no spinning cubes, no glitch
effects, no zoom-punches on text.

## AUDIO (optional; skip the track entirely if you cannot license it)

- Bed: warm Afro-Taarab instrumentation — kalimba/marimba ostinato, soft djembe,
  upright bass, 104 BPM, no vocals, cleared for commercial use.
- Hit points: sizzle (0.0 s), whoosh (3.0 s), soft mallet tick on each dish card
  (7.0 / 7.93 / 8.87 s), UI blips on tracker nodes, coin shimmer (19.2 s),
  warm chime (22.4 s).
- Loudness: −16 LUFS integrated, true peak ≤ −1 dBTP. Duck the bed 4 dB under
  any voice-over.

### Voice-over (record separately, warm Tanzanian Swahili, ~60 words ≈ 22 s)

> Karibu BongoFoodie. Nyama choma ya mkaa, pilau ya viungo, samaki wa kupaka —
> vyote vipikwe moto hapa Kijitonyama. Ongea na Chef AI, unda sahani yako, na
> ufuatilie oda yako hatua kwa hatua. Tumia kodi KARIBU2000 upate punguzo la
> shilingi elfu mbili. BongoFoodie — chakula halisi cha Kiswahili, hadi
> mlangoni kwako.

English alternative:

> Karibu BongoFoodie. Charcoal-grilled beef, spiced pilau, fish in coconut
> cream — cooked hot in Kijitonyama, Dar es Salaam. Talk to Chef AI, design your
> own plate, and follow your order step by step. Use code KARIBU2000 and save
> two thousand shillings. BongoFoodie — real Swahili food, to your door.

## REMOTION IMPLEMENTATION NOTES

```
src/Root.tsx
  <Composition id="BongoFoodiePromo" component={Promo}
    width={1080} height={1920} fps={30} durationInFrames={720}
    defaultProps={{ platform: 'story' }} />
  + "BongoFoodieSquare" 1080×1080 and "BongoFoodieLandscape" 1920×1080,
    same timeline, layout driven by defaultProps.

src/Promo.tsx          Sequence-per-scene, one <AbsoluteFill> per scene
src/scenes/S0Open.tsx … S6EndCard.tsx
src/components/        DishCard, PriceChip, RatingChip, TrackerNode, Pill,
                       SpiceParticles, SteamWisp, LogoLockup
src/theme.ts           every hex above, as tokens — no inline colours
public/assets/…        dishes, icon, fonts
```

- `import { loadFont } from '@remotion/fonts'` or `@remotion/google-fonts`
  pointed at the local TTFs; call `delayRender`/`continueRender` correctly and
  make sure the render does not hang.
- Use `spring({ fps, frame, config })` and `interpolate()` with clamped
  extrapolation. Every animation must be a pure function of `frame`.
- Particles and steam: seeded `random('spice-' + i)`; never re-randomise per
  frame.
- Accent characters: `Ng'ombe` uses a straight apostrophe, `Kijitonyama` has no
  accent. Set `fontVariantNumeric: 'tabular-nums'` on all prices and counters.
- Export: `npx remotion render BongoFoodiePromo out/bongofoodie-promo-9x16.mp4
  --codec=h264 --crf=18 --pixel-format=yuv420p`.

## ACCEPTANCE CHECKLIST (self-check before you answer)

- [ ] 720 frames exactly, 1080×1920, 30 fps, H.264 mp4 that plays in QuickTime.
- [ ] Zero humans, hands, faces or celebrity likeness anywhere in any frame.
- [ ] No AI-generated imagery; only the five dish PNGs, the app icon and the hero.
- [ ] Every price reads `TSh` + no-break space + comma-separated thousands.
- [ ] `KARIBU2000` and `KARIBU BONGO FEAST` spelled exactly; the code equals the
      code in the promo copy.
- [ ] Nothing clipped at 120 px / 190 px / 260 px safe margins; no text under
      44 px; no text on a gradient below 4.5:1 contrast.
- [ ] Quicksand is actually embedded (verify by rendering frame 150).
- [ ] Dish art is not cropped, not recoloured, not re-masked.
- [ ] Frame 630 poster exported; final frame ends on the held end card, ready to
      loop into frame 0.
- [ ] Deterministic: two renders of the same command produce byte-identical
      frames (compare frame 300).
- [ ] Do not add music you cannot license; a silent master is acceptable.

## WHAT "GOOD" LOOKS LIKE

Warm, appetising, confident — a premium restaurant film, not a startup ad. Cream
and ember, one orange accent, real food at generous scale, generous negative
space, slow confident camera moves, type that arrives and settles. Restraint is
the brief: if a frame has three competing focal points, remove one.

---

### Compact version (if the agent truncates long input)

Build a 24 s, 1080×1920, 30 fps Remotion promo for BongoFoodie, a Swahili
food-delivery app in Dar es Salaam. **No humans, faces, hands or celebrity
likeness — food, UI, type and abstract shapes only; no AI-generated images.**
Palette: cream #FAF7F2, ink #2B1B12, ember #1A100B, cta #DE6208, primary
#F58220, primarySoft #FDE8D3, spiceGreen #11543A, gold #F2B33D. Typeface
Quicksand only. Assets at
`https://raw.githubusercontent.com/mwijay12/bongofoodie/6db3987/`:
`mobile/assets/dishes/menu-nyama-choma.png`, `-pilau-kuku.png`,
`-samaki-kupaka.png`, `-chipsi-mayai.png`, `-mishkaki.png`,
`mobile/assets/brand/app-icon-master.png`, `mobile/assets/fonts/Quicksand-*.ttf`.
Scenes: 0–3 s dark cold open with Chipsi Mayai and steam; 3–7 s logo + "Karibu
BongoFoodie" + "Chakula halisi cha Kiswahili kutoka jikoni Kijitonyama hadi
mlangoni kwako."; 7–12.6 s three dish cards — Nyama Choma & Ugali TSh 13,500
★4.9, Zanzibar Pilau TSh 10,000 ★4.8, Samaki wa Kupaka TSh 15,000 ★4.9; 12.6–16.2 s
Chef Atelier AI chat on ember; 16.2–19.2 s receipt TSh 13,500 + TSh 2,000 =
TSh 15,500 with a 4-step tracker (Order placed → Preparing → Ready → Delivered);
19.2–22.4 s green promo card "KARIBU BONGO FEAST", "TSh 2,000 OFF", code
KARIBU2000; 22.4–24 s end card with bongofoodie.vercel.app,
github.com/mwijay12/bongofoodie and a "Get the APK" pill. 12-frame whip
transitions at 90/210/378/486/576/672, spring entrances 280 ms, no confetti, no
glitch, deterministic render, H.264 CRF 18, silent master acceptable.
