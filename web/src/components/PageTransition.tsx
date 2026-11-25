'use client';

import { useEffect, useRef } from 'react';
import { usePathname } from 'next/navigation';
import { gsap, prefersReducedMotion } from '@/lib/motion';

/**
 * Curtain page transition for the Next.js App Router.
 *
 * Barba.js (from the master prompt) targets multi-page sites; inside the
 * App Router it fights the router and causes hard reloads, so this is the
 * equivalent effect built on the existing GSAP stack: an ember curtain
 * with the BongoFoodie wordmark sweeps in, covers, then lifts away on
 * every client-side navigation. Total time is under a second and the
 * overlay never captures pointer events, so it cannot block a task.
 * Skipped entirely for reduced-motion users.
 */
export default function PageTransition() {
  const pathname = usePathname();
  const overlayRef = useRef<HTMLDivElement>(null);
  const firstRender = useRef(true);

  useEffect(() => {
    const overlay = overlayRef.current;
    if (!overlay) return;

    // No curtain on first load — the hero entrance already owns that moment.
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    if (prefersReducedMotion()) return;

    const label = overlay.querySelector('.page-transition-label');

    const tl = gsap.timeline();
    tl.set(overlay, { transformOrigin: 'bottom', scaleY: 0, autoAlpha: 1 })
      .to(overlay, { scaleY: 1, duration: 0.38, ease: 'power3.inOut' })
      .fromTo(
        label,
        { opacity: 0, y: 12 },
        { opacity: 1, y: 0, duration: 0.22, ease: 'power2.out' },
        '-=0.12',
      )
      .to(label, { opacity: 0, y: -10, duration: 0.18, ease: 'power2.in' }, '+=0.08')
      .set(overlay, { transformOrigin: 'top' })
      .to(overlay, { scaleY: 0, duration: 0.5, ease: 'power3.inOut' }, '-=0.05')
      .set(overlay, { autoAlpha: 0 });

    return () => {
      tl.kill();
    };
  }, [pathname]);

  return (
    <div
      ref={overlayRef}
      className="page-transition"
      aria-hidden="true"
      style={{ visibility: 'hidden' }}
    >
      <span className="page-transition-label">
        Bongo<span>Foodie</span>
      </span>
    </div>
  );
}
