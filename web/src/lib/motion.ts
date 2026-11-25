'use client';

/**
 * Central GSAP setup — register every plugin once, here, and import `gsap`
 * from this module everywhere else. Registering in several components used
 * to work by luck; a single owner keeps ScrollTrigger measurements honest
 * when Lenis (SmoothScroll) and page animations share the same ticker.
 *
 * Presets mirror the Awwwards master-prompt animation system, tuned to the
 * BongoFoodie motion tokens in DESIGN.md (150/280/480ms, ease-out entry).
 */

import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(ScrollTrigger);
}

export { gsap, ScrollTrigger };

export const prefersReducedMotion = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/** Magnetic / tilt / cursor effects only make sense with a fine pointer. */
export const isFinePointer = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(pointer: fine)').matches;

/** Shared animation presets — use these instead of ad-hoc tween values. */
export const MOTION_PRESETS = {
  fadeUp: { y: 60, opacity: 0, duration: 0.9, ease: 'power3.out' },
  fadeIn: { opacity: 0, duration: 0.6, ease: 'power2.out' },
  scaleIn: { scale: 0.85, opacity: 0, duration: 0.7, ease: 'back.out(1.7)' },
  slideLeft: { x: -80, opacity: 0, duration: 0.8, ease: 'power3.out' },
  stagger: { stagger: 0.12, ease: 'power2.out' },
  magnetic: { ease: 'power4.out', duration: 0.4 },
} as const;

/**
 * Split an element's text into masked word spans for a staggered rise.
 *
 * The original text is preserved for screen readers via `aria-label` on the
 * element; the visual spans are `aria-hidden`. Runs once per element
 * (guarded by `data-split-done`) so React Strict Mode double-effects and
 * GSAP context reverts cannot nest the spans.
 *
 * Returns the inner word spans, ready for a `gsap.from(..., { yPercent: 110 })`.
 */
export function splitWords(element: HTMLElement): HTMLElement[] {
  if (element.dataset.splitDone) {
    return Array.from(element.querySelectorAll<HTMLElement>('.split-word'));
  }

  const text = element.textContent?.trim() ?? '';
  if (!text) return [];

  element.setAttribute('aria-label', text);
  element.dataset.splitDone = 'true';

  const words = text.split(/\s+/);
  element.textContent = '';

  const fragment = document.createDocumentFragment();
  const spans: HTMLElement[] = [];

  words.forEach((word, index) => {
    const mask = document.createElement('span');
    mask.className = 'split-mask';
    mask.setAttribute('aria-hidden', 'true');

    const inner = document.createElement('span');
    inner.className = 'split-word';
    inner.textContent = word;

    mask.appendChild(inner);
    spans.push(inner);
    fragment.appendChild(mask);

    if (index < words.length - 1) {
      fragment.appendChild(document.createTextNode(' '));
    }
  });

  element.appendChild(fragment);
  return spans;
}

/**
 * Animate a number from 0 to `end` inside `element`, formatted with
 * `decimals` and an optional `prefix`/`suffix` (e.g. "TSh 2,000").
 * The element should already contain the final value in markup so that
 * reduced-motion and no-JS visitors see the real number.
 */
export function countUp(
  element: HTMLElement,
  end: number,
  options: {
    decimals?: number;
    prefix?: string;
    suffix?: string;
    duration?: number;
    delay?: number;
  } = {},
) {
  const { decimals = 0, prefix = '', suffix = '', duration = 1.4, delay = 0 } = options;
  const state = { value: 0 };

  const format = (value: number) =>
    `${prefix}${value.toLocaleString('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    })}${suffix}`;

  element.textContent = format(0);

  return gsap.to(state, {
    value: end,
    duration,
    delay,
    ease: 'power2.out',
    onUpdate: () => {
      element.textContent = format(state.value);
    },
    onComplete: () => {
      element.textContent = format(end);
    },
  });
}
