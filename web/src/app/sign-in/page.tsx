'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';
import { startDemoSession } from '@/lib/supabaseDb';
import { UserRole } from '@/types';
import { Mail, Lock, Loader2, ArrowRight, Eye, EyeOff, Sparkles, ShieldCheck, Bell, User } from 'lucide-react';

export default function SignInPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleDemoAccess = (role: UserRole) => {
    startDemoSession(role);
    if (role === 'admin') {
      router.push('/admin');
    } else if (role === 'waiter') {
      router.push('/waiter');
    } else {
      router.push('/profile');
    }
    router.refresh();
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isSupabaseConfigured) {
      setErrorMsg('Live Supabase keys are not set yet — tap any 1-Click Showcase Role below to explore immediately!');
      return;
    }

    setLoading(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      router.push('/profile');
      router.refresh();
    } catch (err) {
      const error = err as Error;
      let msg = error.message || 'Failed to sign in. Please verify your credentials.';
      if (msg.toLowerCase().includes('confirm') || msg.toLowerCase().includes('invalid login credentials')) {
        msg =
          "Invalid login credentials. If you signed up recently, please confirm your email or disable 'Confirm email' in Supabase Auth -> Providers -> Email for instant sign-in.";
      }
      setErrorMsg(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!isSupabaseConfigured) {
      setErrorMsg('Configure NEXT_PUBLIC_SUPABASE_URL & NEXT_PUBLIC_SUPABASE_ANON_KEY first to send recovery emails.');
      return;
    }
    if (!email.trim()) {
      setErrorMsg('Please type your email address first so we can send the recovery link.');
      return;
    }
    setLoading(true);
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      if (error) throw error;
      setSuccessMsg('A password reset link has been sent to your email address!');
    } catch (err) {
      const error = err as Error;
      setErrorMsg(error.message || 'Failed to send recovery email.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    if (!isSupabaseConfigured) {
      handleDemoAccess('customer');
      return;
    }
    setLoading(true);
    setErrorMsg(null);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/profile`,
        },
      });
      if (error) throw error;
    } catch (err) {
      const error = err as Error;
      setErrorMsg(error.message || 'Failed to authenticate via Google.');
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto py-10 px-6 space-y-6">
      {/* 1-Click Portfolio Showcase Switcher */}
      <div className="bg-gradient-to-br from-amber-50 via-white to-orange-50 border border-primary/25 rounded-3xl p-5 shadow-sm space-y-3">
        <div className="flex items-center gap-2">
          <Sparkles className="size-4 text-primary fill-primary" />
          <h3 className="font-heading text-sm font-extrabold text-foreground-dark">
            Instant Portfolio Showcase Access (1-Click)
          </h3>
        </div>
        <p className="text-[11px] text-muted-foreground font-medium leading-relaxed">
          Explore the complete Bongo Foodie ecosystem immediately as a Customer, Waiter Dispatch operator, or Restaurant Admin:
        </p>
        <div className="grid grid-cols-3 gap-2 pt-1">
          <button
            type="button"
            onClick={() => handleDemoAccess('customer')}
            className="flex flex-col items-center gap-1 p-2.5 rounded-2xl bg-white border border-border hover:border-primary hover:bg-primary/5 transition-all cursor-pointer"
          >
            <User className="size-4 text-primary" />
            <span className="text-[11px] font-bold text-foreground-dark">Customer</span>
            <span className="text-[9px] text-muted-foreground">Order & Track</span>
          </button>
          <button
            type="button"
            onClick={() => handleDemoAccess('waiter')}
            className="flex flex-col items-center gap-1 p-2.5 rounded-2xl bg-white border border-border hover:border-emerald-600 hover:bg-emerald-50 transition-all cursor-pointer"
          >
            <Bell className="size-4 text-emerald-600" />
            <span className="text-[11px] font-bold text-foreground-dark">Waiter POS</span>
            <span className="text-[9px] text-muted-foreground">Live Dispatch</span>
          </button>
          <button
            type="button"
            onClick={() => handleDemoAccess('admin')}
            className="flex flex-col items-center gap-1 p-2.5 rounded-2xl bg-white border border-border hover:border-amber-600 hover:bg-amber-50 transition-all cursor-pointer"
          >
            <ShieldCheck className="size-4 text-amber-600" />
            <span className="text-[11px] font-bold text-foreground-dark">Admin</span>
            <span className="text-[9px] text-muted-foreground">Full Console</span>
          </button>
        </div>
      </div>

      <div className="bg-white border border-border rounded-3xl p-8 shadow-sm space-y-6">
        <div className="text-center space-y-1.5">
          <h2 className="font-heading text-2xl font-bold text-foreground-dark">Welcome Back</h2>
          <p className="text-xs text-muted-foreground font-medium">Log in with Supabase Auth to sync your orders</p>
        </div>

        {errorMsg && (
          <div className="p-3 bg-destructive/5 border border-destructive/20 text-destructive text-xs font-semibold rounded-xl text-center">
            ⚠️ {errorMsg}
          </div>
        )}

        {successMsg && (
          <div className="p-3 bg-green-50 border border-green-200 text-green-700 text-xs font-semibold rounded-xl text-center">
            🎉 {successMsg}
          </div>
        )}

        <form onSubmit={handleSignIn} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Email Address</label>
            <div className="relative">
              <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="e.g. name@email.com"
                className="w-full bg-white border border-border rounded-xl pl-11 pr-4 py-3 text-sm font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <div className="flex justify-between items-center">
              <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Password</label>
              <button
                type="button"
                onClick={handleForgotPassword}
                className="text-xs text-primary hover:underline font-bold focus:outline-none"
              >
                Forgot Password?
              </button>
            </div>
            <div className="relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-white border border-border rounded-xl pl-11 pr-10 py-3 text-sm font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground-dark transition-colors cursor-pointer focus:outline-none"
              >
                {showPassword ? <EyeOff className="size-4.5" /> : <Eye className="size-4.5" />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors shadow-md shadow-primary/10 inline-flex items-center justify-center gap-1.5 cursor-pointer disabled:opacity-50"
          >
            {loading ? (
              <Loader2 className="size-4.5 animate-spin" />
            ) : (
              <>
                Sign In <ArrowRight className="size-4.5" />
              </>
            )}
          </button>
        </form>

        <div className="relative flex py-2 items-center">
          <div className="flex-grow border-t border-border"></div>
          <span className="flex-shrink mx-4 text-muted-foreground text-[10px] font-bold uppercase tracking-wider">
            Or continue with
          </span>
          <div className="flex-grow border-t border-border"></div>
        </div>

        <button
          type="button"
          onClick={handleGoogleSignIn}
          disabled={loading}
          className="w-full py-3 border border-border bg-white text-foreground-dark font-semibold text-xs rounded-xl hover:bg-muted transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          <span>Continue with Google</span>
        </button>

        <div className="text-center pt-2">
          <p className="text-xs text-muted-foreground font-semibold">
            Don&apos;t have an account yet?{' '}
            <Link href="/sign-up" className="text-primary hover:underline">
              Create Account
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
