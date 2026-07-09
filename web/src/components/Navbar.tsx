'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  Home, 
  Search, 
  Sparkles, 
  ShoppingCart, 
  User, 
  Menu,
  Settings,
  Bell
} from 'lucide-react';
import cn from 'clsx';
import { supabase } from '@/lib/supabase';
import { useState, useEffect } from 'react';

export default function Navbar() {
  const pathname = usePathname();
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user?.email === 'defoodordering@gmail.com') {
        setIsAdmin(true);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsAdmin(session?.user?.email === 'defoodordering@gmail.com');
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const navItems = [
    { name: 'Home', href: '/', icon: Home },
    { name: 'Search', href: '/search', icon: Search },
    { name: 'Chef AI', href: '/chef-ai', icon: Sparkles },
    { name: 'Cart', href: '/cart', icon: ShoppingCart },
    ...(isAdmin ? [
      { name: 'Admin', href: '/admin', icon: Settings },
      { name: 'Waiter', href: '/waiter', icon: Bell }
    ] : []),
    { name: 'Profile', href: '/profile', icon: User },
  ];

  return (
    <>
      {/* Top Header (Desktop & Mobile) */}
      <header className="sticky top-0 z-40 w-full border-b border-border bg-white/80 backdrop-blur-md">
        <div className="container mx-auto px-4 md:px-6 h-14 md:h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <span className="font-heading text-lg md:text-xl font-bold text-primary tracking-tight">
              Bongo<span className="text-destructive">Foodie</span>
            </span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-6">
            {navItems.slice(0, 7).map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex items-center gap-2 text-sm font-medium transition-colors py-1.5 px-3 rounded-lg",
                    isActive 
                      ? "text-primary bg-primary/10" 
                      : "text-muted-foreground hover:text-foreground hover:bg-muted"
                  )}
                >
                  <Icon className="size-4" />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>

          {/* Mobile Navigation - horizontal scroll */}
          <nav className="md:hidden flex items-center gap-1 overflow-x-auto no-scrollbar">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex flex-col items-center justify-center px-2 py-1 rounded-lg text-[10px] font-semibold transition-colors min-w-[56px]",
                    isActive ? "text-primary bg-primary/10" : "text-muted-foreground hover:text-foreground"
                  )}
                >
                  <Icon className={cn("size-5 mb-0.5", isActive && "stroke-[2.5px]")} />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>
        </div>
      </header>
    </>
  );
}
