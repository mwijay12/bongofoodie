'use client';

import { useEffect, useState } from 'react';
import {
  isTextSize,
  TEXT_SIZE_OPTIONS,
  TEXT_SIZE_STORAGE_KEY,
  type TextSize,
} from '@/lib/textSize';

/**
 * A small, persistent reading-size control. The root layout applies the saved
 * value before hydration; this component keeps the select and other tabs in
 * sync. CSS scales the rem-based type system instead of zooming the viewport.
 */
export default function TextSizeControl() {
  const [size, setSize] = useState<TextSize>('normal');

  useEffect(() => {
    const sync = () => {
      let stored: string | null = null;
      try {
        stored = window.localStorage.getItem(TEXT_SIZE_STORAGE_KEY);
      } catch {
        // Private browsing can deny storage; normal size still works.
      }
      const next: TextSize = isTextSize(stored) ? stored : 'normal';
      setSize(next);
      document.documentElement.dataset.textSize = next;
    };

    sync();
    const onStorage = (event: StorageEvent) => {
      if (event.key === TEXT_SIZE_STORAGE_KEY) sync();
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const choose = (next: string) => {
    if (!isTextSize(next)) return;
    setSize(next);
    document.documentElement.dataset.textSize = next;
    try {
      window.localStorage.setItem(TEXT_SIZE_STORAGE_KEY, next);
    } catch {
      // The selected size still applies for this page view.
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-x-3 gap-y-1" data-testid="text-size-control">
      <label
        htmlFor="bongo-text-size"
        className="text-xs font-semibold text-muted-foreground whitespace-nowrap"
      >
        Ukubwa wa maandishi <span className="font-normal">/ Text size</span>
      </label>
      <select
        id="bongo-text-size"
        aria-label="Ukubwa wa maandishi / Text size"
        value={size}
        onChange={(event) => choose(event.target.value)}
        className="h-12 min-w-[8.5rem] rounded-full border border-border bg-white px-3 text-sm font-bold text-foreground-dark shadow-sm transition-colors hover:border-primary focus-visible:border-primary"
      >
        {TEXT_SIZE_OPTIONS.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
}
