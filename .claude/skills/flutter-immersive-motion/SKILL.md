---
name: flutter-immersive-motion
description: Refine BongoFoodie Flutter motion and food presentation without changing routes, business logic or adding ornamental dependencies.
---

# BongoFoodie motion

Read AGENTS.md and DESIGN.md first. This skill is project-specific, not a mandate to animate every screen.

## Direction

Food delivery for Dar es Salaam. Warm, grounded, appetising. Cream and charcoal are quiet framing; food carries the colour. The signature is continuity between the dish card and its detail hero, not glowing chrome.

## Rules

- Reuse AppMotion, AppSpace, AppRadius and scoped dish hero tags. Keep routes and provider contracts unchanged.
- Use the existing Flutter SDK animation primitives before proposing a package. Do not add chart, Rive or Lottie packages for unused future features.
- Respect MediaQuery.disableAnimationsOf(context), including changes while mounted. Reduced motion should show the final usable state immediately.
- Never allocate CurvedAnimation in an animation tick. Use a reusable curve transform or manage and dispose animation listeners explicitly.
- Keep static children outside animated builders. Use repaint-driven CustomPainter for future route paths, with RepaintBoundary around the animated region. Do not setState on every painter tick.
- Preserve scoped Hero continuity. No duplicate tags, opaque image backing or image clipping on cutout detail heroes.
- Food assets must match ingredients. Do not substitute beef pilau for chicken pilau or coconut rice. Do not relabel live backend data to match artwork.
- Verify PNG dimensions and actual alpha, not a checkerboard painted into RGB. Review edges over both light and dark surfaces.
- Precache only the small first-screen local hero set. Do not eagerly decode the whole remote menu.
- Keep task feedback short and interruptible. No entrance delay before ordering, looping cart bounce, or animations on every currency label.
- Do not promise 60/120fps from source review; measure on a device in profile mode.

## Check

Run format, analyze, widget tests, asset checks, and theme guardrail. Check Home and detail at 360x640 and 430x932, text scale 1.3, light/dark and reduced motion. Report unavailable tooling or checks explicitly.

## References

- UI audit: https://github.com/heydamir/unslop by Damir Sokolovsky, CC BY 4.0. Keep chrome quiet and richness in product content. Local reference copy: .agents/skills/unslop (ignored by repository convention).
- Copy review: https://github.com/hardikpandya/stop-slop and https://github.com/isatimur/de-slop. Preserve facts; remove vague hype instead of inventing claims.
- Code review: https://stack.convex.dev/how-to-deslop-your-code. Name responsibilities and separate queries from effects; avoid unrelated wholesale rewrites.
- Discovery catalogue: https://www.aitmpl.com/skills/. Review source before installing; web-specific examples are not Flutter APIs.
