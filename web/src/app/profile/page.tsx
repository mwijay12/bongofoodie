'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { User, LogOut, Loader2, Camera, Mail, Save, AlertCircle } from 'lucide-react';
import Image from 'next/image';
import Achievements from '@/components/Achievements';

export default function ProfilePage() {
  const router = useRouter();
  
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  
  // Profile Form States
  const [name, setName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [updating, setUpdating] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Mock stats for achievements geocoding orders count
  const [ordersCount, setOrdersCount] = useState(3);
  const [nyamaChomaCount, setNyamaChomaCount] = useState(1);
  const [chipsiCount, setChipsiCount] = useState(2);
  const [customDishCount, setCustomDishCount] = useState(1);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    setLoading(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session) {
        router.push('/sign-in');
        return;
      }

      setUser(session.user);
      
      // Fetch relational profile row
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('name, avatar_url')
        .eq('id', session.user.id)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (profile) {
        setName(profile.name || '');
        setAvatarUrl(profile.avatar_url || null);
      } else {
        setName(session.user.user_metadata?.full_name || '');
      }

      // Also count actual database orders to dynamic statistics if they exist
      const { count } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('profile_id', session.user.id);
      
      if (count && count > 0) {
        setOrdersCount(count);
      }

    } catch (e: any) {
      console.error(e);
      setMessage({ text: 'Error loading user profile information.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    
    setUpdating(true);
    setMessage(null);

    try {
      const { error } = await supabase
        .from('profiles')
        .upsert({
          id: user.id,
          name,
          email: user.email,
          avatar_url: avatarUrl,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;
      
      setMessage({ text: 'Profile changes saved successfully!', type: 'success' });
    } catch (err: any) {
      console.error(err);
      setMessage({ text: err.message || 'Failed to update profile changes.', type: 'error' });
    } finally {
      setUpdating(false);
    }
  };

  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    setUploading(true);
    setMessage(null);

    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}-${Math.random()}.${fileExt}`;
      const filePath = `avatars/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { cacheControl: '3600', upsert: true });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

      setAvatarUrl(publicUrl);
      
      await supabase
        .from('profiles')
        .update({ avatar_url: publicUrl })
        .eq('id', user.id);

      setMessage({ text: 'Avatar uploaded successfully!', type: 'success' });
    } catch (err: any) {
      console.error('[Avatar Upload Error]', err);
      setMessage({ text: 'Failed to upload photo. Ensure public "avatars" bucket exists.', type: 'error' });
    } finally {
      setUploading(false);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push('/sign-in');
    router.refresh();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-32">
        <Loader2 className="size-8 text-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto py-8 px-4">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        
        {/* Left Column: Form Settings */}
        <div className="lg:col-span-1 bg-white border border-border rounded-3xl p-6 md:p-8 shadow-sm space-y-6">
          <div className="flex items-center justify-between pb-4 border-b border-border">
            <div className="flex items-center gap-3">
              <div className="size-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                <User className="size-5" />
              </div>
              <div>
                <h2 className="font-heading text-base font-bold text-foreground-dark">Your Account</h2>
                <p className="text-[10px] text-muted-foreground font-semibold">Settings coordinates</p>
              </div>
            </div>
            <button
              onClick={handleSignOut}
              className="p-2 hover:bg-destructive/5 text-muted-foreground hover:text-destructive rounded-xl transition-colors cursor-pointer"
              title="Log Out"
            >
              <LogOut className="size-5" />
            </button>
          </div>

          {message && (
            <div className={`p-3 border rounded-xl text-xs font-semibold text-center flex items-center justify-center gap-1.5 ${
              message.type === 'success'
                ? 'bg-emerald-50 border-emerald-200 text-emerald-700'
                : 'bg-destructive/5 border-destructive/20 text-destructive'
            }`}>
              {message.type === 'error' && <AlertCircle className="size-4 shrink-0" />}
              {message.text}
            </div>
          )}

          {/* Admin Redirect Option */}
          {user?.email === 'defoodordering@gmail.com' && (
            <div className="p-4 bg-primary/5 border border-primary/20 rounded-2xl space-y-3">
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-extrabold uppercase bg-primary/20 text-primary px-2.5 py-0.5 rounded-lg">👑 Operator Account</span>
              </div>
              <p className="text-[10px] text-muted-foreground font-semibold leading-normal">
                Access restaurant operator dashboards to manage dishes, active pricing, set promotional offers, and view waiter dispatch coordinates.
              </p>
              <div className="flex flex-col gap-2 pt-1">
                <Link
                  href="/admin"
                  className="w-full py-2.5 bg-primary text-white font-heading font-bold rounded-xl text-xs hover:bg-secondary transition-colors text-center inline-block"
                >
                  Restaurant Admin Panel
                </Link>
                <Link
                  href="/waiter"
                  className="w-full py-2.5 bg-emerald-600 text-white font-heading font-bold rounded-xl text-xs hover:bg-emerald-700 transition-colors text-center inline-block"
                >
                  Waiter Dispatch Board
                </Link>
              </div>
            </div>
          )}

          <form onSubmit={handleUpdateProfile} className="space-y-6">
            <div className="flex flex-col items-center gap-3">
              <div className="size-24 rounded-full border border-border bg-card relative overflow-hidden flex items-center justify-center shadow-inner group">
                {avatarUrl ? (
                  <img
                    src={avatarUrl}
                    alt={name}
                    className="size-full object-cover"
                  />
                ) : (
                  <User className="size-12 text-muted-foreground/35" />
                )}
                {uploading && (
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                    <Loader2 className="size-5 text-white animate-spin" />
                  </div>
                )}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                  className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity text-white cursor-pointer"
                >
                  <Camera className="size-5" />
                </button>
              </div>
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleAvatarUpload}
                accept="image/*"
                className="hidden"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="text-xs font-bold text-primary hover:text-secondary transition-colors"
              >
                Change Photo
              </button>
            </div>

            <div className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Email Address</label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4.5 text-muted-foreground" />
                  <input
                    type="email"
                    disabled
                    value={user?.email || ''}
                    className="w-full bg-muted border border-border rounded-xl pl-11 pr-4 py-3 text-sm font-medium text-muted-foreground select-none"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Display Name</label>
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
            </div>

            <button
              type="submit"
              disabled={updating || uploading}
              className="w-full py-3.5 bg-primary text-white font-heading font-bold rounded-xl hover:bg-secondary transition-colors shadow-md shadow-primary/10 inline-flex items-center justify-center gap-1.5 cursor-pointer disabled:opacity-50"
            >
              {updating ? (
                <Loader2 className="size-4.5 animate-spin" />
              ) : (
                <>
                  <Save className="size-4.5" /> Save Changes
                </>
              )}
            </button>
          </form>
        </div>

        {/* Right Column: Achievements & Badges */}
        <div className="lg:col-span-2 bg-white border border-border rounded-3xl p-6 md:p-8 shadow-sm space-y-6">
          <Achievements 
            ordersCount={ordersCount}
            nyamaChomaCount={nyamaChomaCount}
            chipsiCount={chipsiCount}
            customDishCount={customDishCount}
          />
        </div>

      </div>
    </div>
  );
}
