---
name: premium-ui-motion
description: Design and refine BongoFoodie's Next.js customer experience with purposeful motion, accessible controls and food-led visual hierarchy.
---

# Web motion for BongoFoodie

Read AGENTS.md and DESIGN.md. Apply this guidance to the website; use flutter-immersive-motion for mobile Dart work.

## Product direction

Dar es Salaam food delivery. Warm cream, charcoal and restrained spice-orange accents. Photography carries richness; navigation and layout remain quiet. Preserve working routes, authentication, checkout and staff permissions.

## Motion selection

- Use the installed motion/react for the dish selector and shared selection highlight. Spring baseline: stiffness 300, damping 24. Avoid animating every card on every visit.
- MotionConfig reducedMotion="user" and useReducedMotion must remove rotation, scale and spring movement when requested. CSS entry and hover animation must also respect prefers-reduced-motion.
- Content and primary actions must be visible without JavaScript. Never gate ordering behind entrance animation.
- Do not add GSAP, ScrollTrigger or Lenis unless a specific editorial scroll interaction needs them. Keep native scrolling on ordering, cart, staff and form screens.
- Animate transform and opacity where possible. Filter blur/drop-shadow can cost paint; do not describe all filters as GPU-composited or promise 60fps without profiling.
- Keep interactive feedback interruptible. Avoid looping food float, fake live status pulses, glowing chrome and decorative counters.
- If charts are added to a real analytics task, preserve the dataset and focus state while transitioning. Do not animate financial numbers through misleading intermediate values in operational views.

## Quality gates

- Keyboard-accessible controls, visible focus, meaningful aria-pressed/live announcements and minimum 48px primary touch targets.
- Use genuine transparent food assets. Do not substitute beef imagery for chicken/coconut-rice catalog items. Editorial previews must not imply backend availability, prices or discount eligibility.
- Preserve trivia feedback and existing coupon behavior; never fabricate offers.
- Run TypeScript, scoped ESLint, production build and Playwright tests. Check 360/430px mobile and desktop, reduced motion, image loading, hydration and horizontal overflow.
- Use npm run build then npm run test:ui; install Playwright Chromium with npx playwright install chromium. CHROMIUM_EXECUTABLE_PATH is optional for a managed browser installation.
- Keep generated screenshots, browser binaries and reports out of Git. Report what was measured and what remains unverified.

## References

Motion API: https://github.com/motiondivision/motion
UI direction: https://github.com/heydamir/unslop by Damir Sokolovsky (CC BY 4.0).
Copy review: https://github.com/hardikpandya/stop-slop and https://github.com/isatimur/de-slop.
Library discovery is not a dependency requirement; review source and relevance before adding packages.
