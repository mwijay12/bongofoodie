'use client';

import React, { useState } from 'react';
import { ExternalLink, Smartphone, Tablet, RotateCcw, Sparkles, CheckCircle2 } from 'lucide-react';
import { isSupabaseConfigured } from '@/lib/supabase';

export default function FlutterMobilePreviewPage() {
  const [device, setDevice] = useState<'phone' | 'tablet'>('phone');
  const [reloadKey, setReloadKey] = useState(0);

  const frameWidth = device === 'phone' ? 'w-[392px]' : 'w-[768px]';
  const frameHeight = device === 'phone' ? 'h-[820px]' : 'h-[920px]';

  return (
    <div className="py-6 space-y-8">
      {/* Top Studio Header */}
      <div className="bg-white border border-border rounded-3xl p-6 md:p-8 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        <div className="space-y-2 max-w-2xl">
          <div className="flex flex-wrap items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-extrabold uppercase tracking-wider">
              <Sparkles className="size-3.5" /> Flutter 3 Web Build (`mobile/`)
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-700 text-xs font-extrabold">
              <CheckCircle2 className="size-3.5" />
              {isSupabaseConfigured ? 'Connected to Live Supabase Cloud' : 'Interactive Showcase Mode'}
            </span>
          </div>
          <h1 className="font-heading text-2xl md:text-3xl font-extrabold text-foreground-dark">
            BongoFoodie Flagship Flutter App (Live Web Preview)
          </h1>
          <p className="text-xs md:text-sm text-muted-foreground font-medium leading-relaxed">
            Test the real Flutter mobile codebase (<code className="text-primary font-bold">mobile/lib/main.dart</code> — Riverpod, GoRouter, Material 3 Warm Swahili Luxury, EN/SW bilingual switcher, Chef Atelier AI, Cart &amp; Staff Kitchen Dispatch) directly in your browser or fullscreen on your phone.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <button
            onClick={() => setDevice('phone')}
            className={`inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
              device === 'phone'
                ? 'bg-primary text-white border-primary'
                : 'bg-white text-foreground-dark border-border hover:bg-muted'
            }`}
          >
            <Smartphone className="size-4" /> Phone (392×820)
          </button>
          <button
            onClick={() => setDevice('tablet')}
            className={`hidden md:inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
              device === 'tablet'
                ? 'bg-primary text-white border-primary'
                : 'bg-white text-foreground-dark border-border hover:bg-muted'
            }`}
          >
            <Tablet className="size-4" /> Tablet
          </button>
          <button
            onClick={() => setReloadKey((k) => k + 1)}
            title="Restart Flutter App"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs font-bold border border-border bg-white text-foreground-dark hover:bg-muted transition-all cursor-pointer"
          >
            <RotateCcw className="size-4" /> Restart
          </button>
          <a
            href="/mobile-app/index.html"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-xs font-extrabold bg-foreground-dark text-white hover:bg-primary transition-colors shadow-sm"
          >
            Open Fullscreen <ExternalLink className="size-4" />
          </a>
        </div>
      </div>

      {/* Interactive Device Frame */}
      <div className="flex justify-center">
        <div
          className={`${frameWidth} max-w-full ${frameHeight} bg-[#181C2E] rounded-[44px] p-3.5 shadow-2xl border-4 border-[#2B3040] flex flex-col`}
        >
          {/* Speaker / Dynamic Island Bar */}
          <div className="flex items-center justify-center pb-2.5 pt-1">
            <div className="w-24 h-5 bg-black rounded-full" />
          </div>

          <div className="flex-1 w-full bg-[#120D09] rounded-[32px] overflow-hidden relative">
            <iframe
              key={reloadKey}
              src="/mobile-app/index.html"
              title="BongoFoodie Flutter Mobile App"
              className="w-full h-full border-0"
              allow="clipboard-write"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
