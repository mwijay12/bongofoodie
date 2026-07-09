'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Mail, Lock, User, Phone, Loader2, ArrowRight, Eye, EyeOff, X } from 'lucide-react';

export default function SignUpPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [agree, setAgree] = useState(false);
  const [showTerms, setShowTerms] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!agree) {
      setErrorMsg("You must agree to the Terms & Conditions.");
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: name,
            phone: phone,
          }
        }
      });

      if (error) throw error;

      // If user successfully registered, create their profile row
      if (data.user) {
        await supabase.from('profiles').insert({
          id: data.user.id,
          name,
          email,
        });
      }

      alert("Registration successful! If email confirmation is enabled, please verify your email address before signing in.");
      router.push('/profile');
      router.refresh();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      setErrorMsg(message || 'Failed to register account. Please check inputs.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignUp = async () => {
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
      const message = err instanceof Error ? err.message : String(err);
      setErrorMsg(message || 'Failed to authenticate via Google.');
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto py-12 px-6">
      <div className="bg-white border border-border rounded-3xl p-8 shadow-sm space-y-6">
        <div className="text-center space-y-1.5">
          <h2 className="font-heading text-2xl font-bold text-foreground-dark">Create Account</h2>
          <p className="text-xs text-muted-foreground font-medium">Join Bongo Foodie Swahili culinary workspace</p>
        </div>

        {errorMsg && (
          <div className="p-3 bg-destructive/5 border border-destructive/20 text-destructive text-xs font-semibold rounded-xl text-center">
            ⚠️ {errorMsg}
          </div>
        )}

        <form onSubmit={handleSignUp} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Full Name</label>
            <div className="relative">
              <User className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Juma Kassim"
                className="w-full bg-white border border-border rounded-xl pl-11 pr-4 py-3 text-sm font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
              />
            </div>
          </div>

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
            <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Phone Number</label>
            <div className="relative">
              <Phone className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
              <input
                type="tel"
                required
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="e.g. 0712345678"
                className="w-full bg-white border border-border rounded-xl pl-11 pr-4 py-3 text-sm font-medium text-foreground-dark focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Password</label>
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

          {/* Terms checkbox */}
          <div className="flex items-center gap-2.5 py-1">
            <input
              type="checkbox"
              id="agree"
              checked={agree}
              onChange={(e) => setAgree(e.target.checked)}
              className="rounded text-primary border-border focus:ring-primary size-4 cursor-pointer"
            />
            <label htmlFor="agree" className="text-xs text-muted-foreground font-semibold cursor-pointer select-none">
              I agree to the{' '}
              <button
                type="button"
                onClick={() => setShowTerms(true)}
                className="text-primary font-bold hover:underline focus:outline-none inline"
              >
                Terms & Conditions
              </button>
            </label>
          </div>

          <button
            type="submit"
            disabled={loading || !agree}
            className="w-full py-3.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors shadow-md shadow-primary/10 inline-flex items-center justify-center gap-1.5 cursor-pointer disabled:opacity-50"
          >
            {loading ? (
              <Loader2 className="size-4.5 animate-spin" />
            ) : (
              <>
                Register Account <ArrowRight className="size-4.5" />
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
          onClick={handleGoogleSignUp}
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
            Already have an account?{' '}
            <Link href="/sign-in" className="text-primary hover:underline">
              Log In
            </Link>
          </p>
        </div>
      </div>

      {/* Terms Modal */}
      {showTerms && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-6">
          <div className="bg-white rounded-3xl w-full max-w-lg overflow-hidden flex flex-col h-[80%] max-h-[600px] shadow-2xl animate-in fade-in zoom-in duration-200">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-border">
              <h3 className="font-heading text-lg font-bold text-foreground-dark">Terms & Conditions</h3>
              <button 
                onClick={() => setShowTerms(false)}
                className="p-1.5 rounded-full hover:bg-muted text-muted-foreground hover:text-foreground-dark transition-colors cursor-pointer"
              >
                <X className="size-5" />
              </button>
            </div>
            {/* Scrollable text */}
            <div className="flex-1 overflow-y-auto p-6 space-y-4 text-xs text-muted-foreground font-semibold leading-relaxed">
              <p className="text-foreground-dark font-bold text-sm">
                Welcome to Bongo Foodie. By using our website and services, you agree to comply with and be bound by the following terms.
              </p>

              <h4 className="font-bold text-foreground-dark text-sm mt-4">1. Ordering & Service Execution</h4>
              <p>
                Bongo Foodie coordinates with local kitchens to prepare your meals. Delivery times are estimated and subject to kitchen load, weather, and Dar es Salaam traffic conditions.
              </p>

              <h4 className="font-bold text-foreground-dark text-sm mt-4">2. Payments & Digital Settlements</h4>
              <p>
                All digital transactions via mobile money (M-Pesa, Tigo Pesa Lipa Namba) must settle exactly to the admin configured Till accounts. Cash orders are settled on hand-over.
              </p>

              <h4 className="font-bold text-foreground-dark text-sm mt-4">3. Chef AI Recipes</h4>
              <p>
                The Chef AI assistant generates digital dish visuals, nutritional estimations, and customized recipe pairing guides for culinary discovery. Always verify sensitivities and food allergies independently.
              </p>

              <h4 className="font-bold text-foreground-dark text-sm mt-4">4. User Account Integrity</h4>
              <p>
                You agree to supply a valid phone number and keep your credentials confidential. We encrypt and safeguard user metadata.
              </p>

              <p className="text-[10px] text-muted-foreground/80 italic pt-4">
                Last updated: July 2026. Bongo Foodie Culinary Services.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
