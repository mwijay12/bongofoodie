'use client';

import { useEffect, useRef } from 'react';
import { gsap, isFinePointer, prefersReducedMotion } from '@/lib/motion';

/**
 * Trailing cursor accent: a hot-orange dot that tracks the pointer 1:1 and
 * a ring that eases behind it, growing over links, buttons and anything
 * marked `data-cursor`. The native cursor stays visible — hiding it breaks
 * usability for low-vision and motor-impaired visitors, and the ring is
 * meant as a brand accent, not a replacement.
 *
 * Renders nothing on touch devices and for reduced-motion users.
 */
export default function CustomCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (prefersReducedMotion() || !isFinePointer()) return;

    const dot = dotRef.current;
    const ring = ringRef.current;
    if (!dot || !ring) return;

    gsap.set([dot, ring], { xPercent: -50, yPercent: -50, x: -100, y: -100 });

    const dotX = gsap.quickTo(dot, 'x', { duration: 0.08, ease: 'power2.out' });
    const dotY = gsap.quickTo(dot, 'y', { duration: 0.08, ease: 'power2.out' });
    const ringX = gsap.quickTo(ring, 'x', { duration: 0.35, ease: 'power3.out' });
    const ringY = gsap.quickTo(ring, 'y', { duration: 0.35, ease: 'power3.out' });

    let shown = false;
    const show = () => {
      if (shown) return;
      shown = true;
      gsap.to([dot, ring], { opacity: 1, duration: 0.3 });
    };

    const onMove = (event: PointerEvent) => {
      show();
      dotX(event.clientX);
      dotY(event.clientY);
      ringX(event.clientX);
      ringY(event.clientY);
    };

    const onOver = (event: MouseEvent) => {
      const target = event.target as HTMLElement | null;
      const interactive = target?.closest('a, button, [data-cursor]');
      gsap.to(ring, {
        scale: interactive ? 1.9 : 1,
        opacity: interactive ? 0.9 : 0.55,
        duration: 0.3,
        ease: 'power2.out',
      });
    };

    window.addEventListener('pointermove', onMove, { passive: true });
    window.addEventListener('mouseover', onOver, { passive: true });

    return () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('mouseover', onOver);
    };
  }, []);

  if (typeof window !== 'undefined' && (prefersReducedMotion() || !isFinePointer())) {
    return null;
  }

  return (
    <>
      <div ref={dotRef} className="custom-cursor-dot" aria-hidden="true" />
      <div ref={ringRef} className="custom-cursor-ring" aria-hidden="true" />
    </>
  );
}
