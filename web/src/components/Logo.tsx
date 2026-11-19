'use client';

import { useId } from 'react';

/**
 * The BongoFoodie bowl mark, drawn in code from the same geometry as the
 * favicon: ember field, hot orange bowl, foot and two cream steam curls.
 * `variant="mark"` is the icon alone; `variant="lockup"` adds the wordmark.
 */
export default function Logo({
  size = 34,
  variant = 'mark',
  className,
  wordmarkClassName,
  animate = false,
}: {
  size?: number;
  variant?: 'mark' | 'lockup';
  className?: string;
  wordmarkClassName?: string;
  animate?: boolean;
}) {
  const id = useId().replace(/:/g, '');
  const gid = `logo-grad-${id}`;

  const mark = (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      className={className}
      aria-hidden={variant === 'mark' ? 'true' : undefined}
      role={variant === 'mark' ? undefined : 'img'}
    >
      <defs>
        <linearGradient id={gid} x1="12" y1="28" x2="52" y2="48" gradientUnits="userSpaceOnUse">
          <stop stopColor="#F58220" />
          <stop offset="1" stopColor="#E8551A" />
        </linearGradient>
      </defs>
      <circle cx="32" cy="32" r="31" fill="#1A100B" />
      <g
        stroke="#FAF7F2"
        strokeWidth="5"
        strokeLinecap="round"
        opacity={animate ? 0.92 : 1}
        className={animate ? 'logo-steam' : undefined}
      >
        <path d="M24 22c-3-3 3-6 0-10" />
        <path d="M40 22c3-3-3-6 0-10" />
      </g>
      <rect x="27" y="46" width="10" height="7" rx="3.5" fill="#E8551A" />
      <path d="M12 28h40c0 11.5-8.5 20-20 20S12 39.5 12 28Z" fill={`url(#${gid})`} />
    </svg>
  );

  if (variant === 'mark') return mark;

  return (
    <span className="inline-flex items-center gap-2">
      {mark}
      <span className={wordmarkClassName ?? 'font-heading font-bold tracking-tight'}>
        Bongo<span className="text-primary">Foodie</span>
      </span>
    </span>
  );
}
