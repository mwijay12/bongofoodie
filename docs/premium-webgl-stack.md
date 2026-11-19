# Premium website stack — where to learn each piece

A curated map for building award-level sites with WebGL, GLSL, Barba.js, Anime.js,
Tween.js and GSAP — chosen for **AI-agent work**, so each entry says what to steal
from it. Star counts checked 2026-11-15 via the GitHub API.

---

## 1. The six libraries you named

| Library | Repo | Stars | What it is actually for |
| --- | --- | --- | --- |
| **GSAP** | [`greensock/GSAP`](https://github.com/greensock/GSAP) | 30.6k | The industry standard timeline engine. ScrollTrigger, SplitText, Flip, MorphSVG. Free for most uses since 2025. |
| **GSAP + AI** | [`greensock/gsap-skills`](https://github.com/greensock/gsap-skills) | 18.5k | **Official** skills that teach AI coding agents correct GSAP. Read this first — it stops an agent inventing wrong API calls. |
| **Anime.js** | [`juliangarnier/anime`](https://github.com/juliangarnier/anime) | 74.7k | v4 is a rewrite: a smaller, more declarative GSAP alternative. Good for SVG morphs and staggered grids. |
| **Tween.js** | [`tweenjs/tween.js`](https://github.com/tweenjs/tween.js) | 10.2k | Bare interpolation engine. Use it when you *own* the render loop — games, canvas, 3D — not for DOM. |
| **Barba.js** | [`barbajs/barba`](https://github.com/barbajs/barba) | 13.0k | Page transitions for multi-page sites. **Requires a classic MPA** — it is why Quickopia-style sites feel instant between pages. |
| **Lenis** | [`darkroomengineering/lenis`](https://github.com/darkroomengineering/lenis) | 17.3k | Smooth scroll done right. Pairs with GSAP ScrollTrigger; almost every Awwwards site uses this or a clone. |

**Do not install all six.** A realistic premium stack is:

```
Next.js (App Router) + GSAP + ScrollTrigger + Lenis
                     └─ Anime.js only if you need SVG morphs GSAP won't do
                     └─ Barba only on a non-Next MPA — Next has its own transitions
                     └─ Tween.js only inside a custom canvas/Three render loop
```

Next.js already does client-side navigation, so **Barba is redundant here**. That
is worth knowing before an agent wires up both and fights itself.

---

## 2. WebGL and GLSL

| Repo | Stars | Use it for |
| --- | --- | --- |
| [`mrdoob/three.js`](https://github.com/mrdoob/three.js) | 118k | The default. 3D scenes, custom `ShaderMaterial`, post-processing. |
| [`pmndrs/react-three-fiber`](https://github.com/pmndrs/react-three-fiber) | 33.7k | Three.js as React components. The right choice inside Next.js. |
| [`oframe/ogl`](https://github.com/oframe/ogl) | 4.8k | **Minimal** WebGL — ~30 KB. For a shader background, this beats 600 KB of three. |
| [`patriciagonzalezvivo/lygia`](https://github.com/patriciagonzalezvivo/lygia) | 3.5k | A **shader standard library** — noise, SDFs, lighting. Copy functions from here instead of writing them. |
| [`patriciagonzalezvivo/glslViewer`](https://github.com/patriciagonzalezvivo/glslViewer) | 5.4k | Live GLSL sandbox on desktop. Fastest way to iterate on a shader. |
| [`stackgl/shader-school`](https://github.com/stackgl/shader-school) | 4.4k | If GLSL is new: a guided workshop, not docs. |
| [`xemantic/shader-web-background`](https://github.com/xemantic/shader-web-background) | 289 | Drop-in full-screen GLSL background. Exactly what `HeatShader.tsx` does, but generalised. |
| [`ruucm/shadergradient`](https://github.com/ruucm/shadergradient) | 3.2k | Moving gradient meshes; useful for hero backdrops without writing noise by hand. |
| [`martinlaxenaire/curtainsjs`](https://github.com/martinlaxenaire/curtainsjs) | 1.8k | Turns HTML `<img>` into WebGL planes — image hover distortion, page transitions. |

### Shader live-coding, worth an hour
- [Shadertoy](https://www.shadertoy.com) — the corpus. Search "smoke", "steam", "liquid".
- [The Book of Shaders](https://thebookofshaders.com) — the canonical text.
- [lygia on Shadertoy](https://www.shadertoy.com/user/patriciogonzalezvivo) — production-grade functions.

---

## 3. Reference sites and repos to study

| Repo | Stars | Why |
| --- | --- | --- |
| [`terkelg/awesome-creative-coding`](https://github.com/terkelg/awesome-creative-coding) | 15.6k | **Start here.** The single best index: generative art, shaders, interaction, tools. Agent-friendly because it is a list, not prose. |
| [`adrianhajdin/project_3D_developer_portfolio`](https://github.com/adrianhajdin/project_3D_developer_portfolio) | 7.1k | A complete Three.js portfolio with a tutorial. Copy the scene graph, not the content. |
| [`fireship-io/threejs-scroll-animation-demo`](https://github.com/fireship-io/threejs-scroll-animation-demo) | 1.7k | Scroll-driven 3D camera. The exact effect most premium sites open with. |
| [`poojahooda22/motion-website`](https://github.com/poojahooda22/motion-website) | 204 | An Awwwards site **cloned** with GSAP + Framer Motion. Best single file to read for "how do they time this". |
| [`Temitayo-spec/Raft-Landing-Page`](https://github.com/Temitayo-spec/Raft-Landing-Page) | 356 | Small Next.js + GSAP + framer-motion landing page. Realistic scope. |
| [`Leonxlnx/lumenshaders`](https://github.com/Leonxlnx/lumenshaders) | 367 | A generative shader studio, 9 WebGL2 modes. Good architecture reference. |
| [`fireship-io`](https://github.com/fireship-io) generally | — | Short, working demos of almost every technique. |

Also worth bookmarking: [Codrops](https://tympanus.net/codrops/) (new technique
every week, full source) and [Awwwards](https://www.awwwards.com) (the target).

---

## 4. Practical order of operations

1. **Motion first, effects second.** A site with perfect GSAP timing and no
   shader beats a shader showcase with sloppy motion. Learn ScrollTrigger.
2. **One GPU surface, maximum.** Every additional WebGL canvas costs a separate
   context. `HeatShader.tsx` in this repo is one quad for that reason.
3. **Ship the reduced-motion path.** `prefers-reduced-motion` is not optional —
   Google, and every reviewer, checks it.
4. **Budget the bundle.** OGL + your shader ≈ 30 KB. Three.js + drei ≈ 700 KB.
   Match the tool to the effect.
5. **Loop hygiene.** Pause `requestAnimationFrame` on `visibilitychange` and off
   screen. A hero shader that burns battery is a bug, not a feature.

---

## 5. If you wire an AI agent to this

- Give it **`greensock/gsap-skills`** before any animation task. It is written
  for exactly this.
- Tell it **which** library to use per effect. Left alone, it will install GSAP
  *and* Framer Motion *and* Anime.js and produce three competing timelines.
- Point it at **lygia** for shader functions instead of letting it write noise
  from scratch — hand-written noise is where shader bugs live.
- Ask for `prefers-reduced-motion`, `visibilitychange` and a DPR cap in the
  first prompt. Retrofitting them never happens.

## 6. Related, in this repo

- `web/src/app/page.tsx` — the landing page is deliberately **not** WebGL. A
  Three.js plate (`fiber` + `drei` + an `Environment` HDR fetched at runtime)
  cost roughly 700 KB of client JS, a second GPU surface and a per-frame loop
  on first paint. It was replaced with a CSS/`<Image>` editorial plate built
  from optimised 85 KB WebP dish cutouts. Keep the stack above for reference,
  not for the storefront's first screen.
- `web/src/components/HeatShader.tsx` — a working hand-written GLSL plume: one
  quad, one fragment shader, reduced-motion and off-screen safe. Reference
  implementation only; it is not mounted on the landing page.
- `web/src/app/globals.css` — the single palette all of the above should use.
- `docs/promo-video-prompt.md` — the code-to-video brief, same design tokens.
