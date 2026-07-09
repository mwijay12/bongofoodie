'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Lock, Loader2, Eye, EyeOff, CheckCircle } from 'lucide-react';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password.length < 6) {
      setErrorMsg('Password must be at least 6 characters long.');
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    try {
      const { error } = await supabase.auth.updateUser({
        password: password,
      });

      if (error) throw error;

      setSuccess(true);
      setTimeout(() => {
        router.push('/sign-in');
      }, 3000);
    } catch (err) {
      const error = err as Error;
      setErrorMsg(error.message || 'Failed to update your password. Please trigger a new recovery link.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto py-12 px-6">
      <div className="bg-white border border-border rounded-3xl p-8 shadow-sm space-y-6">
        <div className="text-center space-y-1.5">
          <h2 className="font-heading text-2xl font-bold text-foreground-dark">Reset Password</h2>
          <p className="text-xs text-muted-foreground font-medium">Type your new secure account password below</p>
        </div>

        {errorMsg && (
          <div className="p-3 bg-destructive/5 border border-destructive/20 text-destructive text-xs font-semibold rounded-xl text-center">
            ⚠️ {errorMsg}
          </div>
        )}

        {success ? (
          <div className="p-6 bg-green-50 border border-green-200 text-green-700 text-sm font-semibold rounded-2xl text-center space-y-2">
            <CheckCircle className="size-8 mx-auto text-green-600 animate-bounce" />
            <p>Password updated successfully!</p>
            <p className="text-xs text-muted-foreground font-medium">Redirecting you to the login screen in a few seconds...</p>
          </div>
        ) : (
          <form onSubmit={handleReset} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">New Password</label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Min 6 characters"
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
                "Save Password"
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
