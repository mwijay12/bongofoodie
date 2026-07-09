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
      {/* Desktop Header */}
      <header className="hidden md:flex sticky top-0 z-40 w-full border-b border-border bg-white/80 backdrop-blur-md">
        <div className="container mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <span className="font-heading text-xl font-bold text-primary tracking-tight">
              Bongo<span className="text-destructive">Foodie</span>
            </span>
          </Link>

          <nav className="flex items-center gap-6">
            {navItems.map((item) => {
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
        </div>
      </header>

      {/* Mobile Bottom Navigation */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 border-t border-border backdrop-blur-md pb-safe">
        <div className="flex h-16 items-center justify-around px-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex flex-col items-center justify-center flex-1 h-full py-1 text-xs font-semibold transition-colors",
                  isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className={cn("size-6 mb-1", isActive && "stroke-[2.5px]")} />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </>
  );
}
