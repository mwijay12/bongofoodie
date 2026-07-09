'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Mail, Lock, Loader2, ArrowRight, Eye, EyeOff } from 'lucide-react';

export default function SignInPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
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
      if (msg.toLowerCase().includes("confirm") || msg.toLowerCase().includes("invalid login credentials")) {
        msg = "Invalid login credentials. If you signed up recently, please confirm your email via the link sent or verify your password. (You can disable 'Confirm email' in Supabase Auth Providers setting to sign in instantly during local development).";
      }
      setErrorMsg(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
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
      setSuccessMsg('A password reset link has been successfully sent to your email address!');
    } catch (err) {
      const error = err as Error;
      setErrorMsg(error.message || 'Failed to send recovery email.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/profile`
        }
      });
      if (error) throw error;
    } catch (err) {
      const error = err as Error;
      setErrorMsg(error.message || 'Failed to authenticate via Google.');
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto py-12 px-6">
      <div className="bg-white border border-border rounded-3xl p-8 shadow-sm space-y-6">
        <div className="text-center space-y-1.5">
          <h2 className="font-heading text-2xl font-bold text-foreground-dark">Welcome Back</h2>
          <p className="text-xs text-muted-foreground font-medium">Log in to manage your orders and profile</p>
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
          <span className="flex-shrink mx-4 text-muted-foreground text-[10px] font-bold uppercase tracking-wider">Or continue with</span>
          <div className="flex-grow border-t border-border"></div>
        </div>

        <button
          type="button"
          onClick={handleGoogleSignIn}
          disabled={loading}
          className="w-full py-3 border border-border bg-white text-foreground-dark font-semibold text-xs rounded-xl hover:bg-muted transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          <svg className="size-4 shrink-0" viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
            <g transform="matrix(1, 0, 0, 1, 0, 0)">
              <path d="M21.35,11.1H12v2.7h5.38c-0.24,1.28 -0.96,2.37 -2.04,3.1v2.58h3.3c1.93,-1.78 3.04,-4.4 3.04,-7.4C21.68,11.96 21.56,11.5 21.35,11.1z" fill="#4285F4" />
              <path d="M12,20.6c2.59,0 4.77,-0.86 6.36,-2.32l-3.3,-2.58c-0.91,0.61 -2.08,0.97 -3.06,0.97 -2.35,0 -4.35,-1.59 -5.06,-3.72H3.5v2.66C5.12,18.77 8.35,20.6 12,20.6z" fill="#34A853" />
              <path d="M6.94,12.93c-0.18,-0.54 -0.28,-1.11 -0.28,-1.7c0,-0.59 0.1,-1.16 0.28,-1.7V6.87H3.5C2.88,8.12 2.52,9.52 2.52,11c0,1.48 0.36,2.88 0.98,4.13L6.94,12.93z" fill="#FBBC05" />
              <path d="M12,5.2c1.41,0 2.68,0.49 3.68,1.44l2.76,-2.76C16.77,2.32 14.59,1.4 12,1.4 8.35,1.4 5.12,3.23 3.5,6.87l3.44,2.66C7.65,6.79 9.65,5.2 12,5.2z" fill="#EA4335" />
            </g>
          </svg>
          <span>Continue with Google</span>
        </button>

        <div className="text-center pt-2">
          <p className="text-xs text-muted-foreground font-semibold">
            Don't have an account yet?{' '}
            <Link href="/sign-up" className="text-primary hover:underline">
              Create Account
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
