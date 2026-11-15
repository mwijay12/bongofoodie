'use client';

import { useId } from 'react';

/**
 * The BongoFoodie mark, drawn in code.
 *
 * The old bitmap logo (`public/assets/logo.png`) was forest green with a gold
 * leaf — a colour scheme that appears nowhere else in the product, sitting on an
 * orange site. This mark uses only the shipping palette: ember disc, hot orange
 * pot, cream steam. It is SVG so it stays crisp at any size and the steam can be
 * animated by CSS without a second asset.
 *
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
        <linearGradient id={gid} x1="14" y1="26" x2="50" y2="52" gradientUnits="userSpaceOnUse">
          <stop stopColor="#F58220" />
          <stop offset="1" stopColor="#E8551A" />
        </linearGradient>
      </defs>

      {/* Ember disc */}
      <circle cx="32" cy="32" r="31" fill="#16100B" />

      {/* Pot body */}
      <path
        d="M15 33h34v7a13 13 0 0 1-13 13h-8a13 13 0 0 1-13-13v-7Z"
        fill={`url(#${gid})`}
      />
      {/* Handles */}
      <path d="M12 36h3v6h-3a3 3 0 0 1 0-6Z" fill="#F58220" />
      <path d="M49 36h3a3 3 0 0 1 0 6h-3v-6Z" fill="#F58220" />
      {/* Domed lid */}
      <path
        d="M17 31a15 15 0 0 1 30 0H17Z"
        fill="#FFB347"
      />
      {/* Lid rim */}
      <rect x="13.5" y="29.5" width="37" height="4" rx="2" fill="#FAF7F2" />
      {/* Knob */}
      <circle cx="32" cy="14.5" r="2.6" fill="#FAF7F2" />

      {/* Steam — animated on hover/first paint when requested */}
      <g
        stroke="#FAF7F2"
        strokeWidth="2.4"
        strokeLinecap="round"
        opacity="0.9"
        className={animate ? 'logo-steam' : undefined}
      >
        <path d="M26 9.5c-1.6-1.6 1.6-3 -0-4.6" />
        <path d="M38 9.5c-1.6-1.6 1.6-3 -0-4.6" />
      </g>
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
