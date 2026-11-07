'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  Search,
  Sparkles,
  ShoppingCart,
  User,
  Settings,
  Bell,
  Smartphone,
} from 'lucide-react';
import cn from 'clsx';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';
import { getActiveUserProfile } from '@/lib/supabaseDb';
import { useCartStore } from '@/store/cart.store';
import { UserRole } from '@/types';

export default function Navbar() {
  const pathname = usePathname();
  const [role, setRole] = useState<UserRole | null>(null);
  const [isDemo, setIsDemo] = useState(false);
  const totalItems = useCartStore((state) => state.getTotalItems());

  useEffect(() => {
    const syncAuth = async () => {
      const profile = await getActiveUserProfile();
      setRole(profile?.role || null);
      setIsDemo(Boolean(profile?.isDemo));
    };

    syncAuth();

    window.addEventListener('bongo-auth-changed', syncAuth);

    let unsub: (() => void) | undefined;
    if (isSupabaseConfigured) {
      const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
        syncAuth();
      });
      unsub = () => subscription.unsubscribe();
    }

    return () => {
      window.removeEventListener('bongo-auth-changed', syncAuth);
      unsub?.();
    };
  }, []);

  const showAdmin = role === 'admin';
  const showWaiter = role === 'admin' || role === 'waiter' || role === 'kitchen';

  const navItems = [
    { name: 'Home', href: '/', icon: Home },
    { name: 'Search', href: '/search', icon: Search },
    { name: 'Chef AI', href: '/chef-ai', icon: Sparkles },
    { name: 'Flutter App', href: '/mobile', icon: Smartphone },
    { name: 'Cart', href: '/cart', icon: ShoppingCart, badge: totalItems },
    ...(showWaiter ? [{ name: 'Waiter', href: '/waiter', icon: Bell }] : []),
    ...(showAdmin ? [{ name: 'Admin', href: '/admin', icon: Settings }] : []),
    { name: 'Profile', href: '/profile', icon: User },
  ];

  return (
    <header className="sticky top-0 z-40 w-full border-b border-border bg-white/85 backdrop-blur-md">
      <div className="container mx-auto px-4 md:px-6 h-14 md:h-16 flex items-center justify-between gap-3">
        <Link href="/" className="flex items-center gap-2 shrink-0">
          <span className="font-heading text-lg md:text-xl font-bold text-primary tracking-tight">
            Bongo<span className="text-destructive">Foodie</span>
          </span>
          {(!isSupabaseConfigured || isDemo) && (
            <span className="hidden sm:inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-amber-500/15 text-amber-700 border border-amber-500/30">
              {isDemo ? `Demo: ${role}` : 'Showcase'}
            </span>
          )}
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-4 lg:gap-6">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'relative flex items-center gap-2 text-sm font-medium transition-colors py-1.5 px-3 rounded-lg',
                  isActive
                    ? 'text-primary bg-primary/10'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted',
                )}
              >
                <Icon className="size-4" />
                <span>{item.name}</span>
                {item.badge && item.badge > 0 ? (
                  <span className="ml-0.5 px-1.5 py-0.2 rounded-full bg-primary text-white text-[10px] font-bold">
                    {item.badge}
                  </span>
                ) : null}
              </Link>
            );
          })}
        </nav>

        {/* Mobile Navigation */}
        <nav className="md:hidden flex items-center gap-1 overflow-x-auto no-scrollbar">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'relative flex flex-col items-center justify-center px-2 py-1 rounded-lg text-[10px] font-semibold transition-colors min-w-[54px]',
                  isActive ? 'text-primary bg-primary/10' : 'text-muted-foreground hover:text-foreground',
                )}
              >
                <Icon className={cn('size-5 mb-0.5', isActive && 'stroke-[2.5px]')} />
                <span>{item.name}</span>
                {item.badge && item.badge > 0 ? (
                  <span className="absolute top-0.5 right-1 size-4 rounded-full bg-primary text-white text-[9px] font-bold flex items-center justify-center">
                    {item.badge}
                  </span>
                ) : null}
              </Link>
            );
          })}
        </nav>
      </div>
    </header>
  );
}
