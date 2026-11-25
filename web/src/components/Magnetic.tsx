'use client';

import { useRef, type ReactNode, type MouseEvent } from 'react';
import { gsap, isFinePointer, prefersReducedMotion } from '@/lib/motion';

/**
 * Magnetic hover wrapper for CTA buttons and links.
 *
 * The wrapped element leans toward the pointer (GSAP QuickTo, `power4.out`)
 * and springs back with an elastic ease on leave. Disabled entirely for
 * reduced-motion users and coarse pointers (touch), where it would only
 * fight the scroll. The native cursor is left alone.
 */
export default function Magnetic({
  children,
  strength = 0.35,
  className,
}: {
  children: ReactNode;
  /** Fraction of the pointer offset the element follows (0–1). */
  strength?: number;
  className?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  const handleMove = (event: MouseEvent<HTMLSpanElement>) => {
    const el = ref.current;
    if (!el || prefersReducedMotion() || !isFinePointer()) return;

    const rect = el.getBoundingClientRect();
    const x = event.clientX - (rect.left + rect.width / 2);
    const y = event.clientY - (rect.top + rect.height / 2);

    gsap.to(el, {
      x: x * strength,
      y: y * strength,
      duration: 0.4,
      ease: 'power4.out',
      overwrite: 'auto',
    });
  };

  const handleLeave = () => {
    const el = ref.current;
    if (!el) return;
    gsap.to(el, {
      x: 0,
      y: 0,
      duration: 0.7,
      ease: 'elastic.out(1, 0.4)',
      overwrite: 'auto',
    });
  };

  return (
    <span
      ref={ref}
      className={className}
      style={{ display: 'inline-flex', willChange: 'transform' }}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
    >
      {children}
    </span>
  );
}
