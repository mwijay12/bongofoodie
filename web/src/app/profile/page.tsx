'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { User, LogOut, Loader2, Camera, Mail, Save, AlertCircle, Receipt, Heart, MapPin, HelpCircle, FileText, ChevronRight, X, Clock, CheckCircle2, XCircle, Package, ChefHat, Star } from 'lucide-react';
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

  // Modal state
  const [activeModal, setActiveModal] = useState<string | null>(null);

  // Orders state
  const [orders, setOrders] = useState<any[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);

  // Favorites state
  const [favorites, setFavorites] = useState<any[]>([]);
  const [loadingFavorites, setLoadingFavorites] = useState(false);

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

  const loadOrders = async () => {
    if (!user?.id) return;
    setLoadingOrders(true);
    try {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .eq('profile_id', user.id)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      setOrders(data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingOrders(false);
    }
  };

  const loadFavorites = async () => {
    if (!user?.id) return;
    setLoadingFavorites(true);
    try {
      const { data, error } = await supabase
        .from('favorites')
        .select('*, menu_items(*)')
        .eq('user_id', user.id);
      
      if (error) throw error;
      setFavorites(data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingFavorites(false);
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

  const openModal = async (type: string) => {
    setActiveModal(type);
    if (type === 'orders') {
      await loadOrders();
    } else if (type === 'favorites') {
      await loadFavorites();
    }
  };

  const getStatusColor = (status: string) => {
    const map: Record<string, string> = {
      pending: 'bg-amber-100 text-amber-700 border-amber-200',
      preparing: 'bg-blue-100 text-blue-700 border-blue-200',
      in_transit: 'bg-purple-100 text-purple-700 border-purple-200',
      out_for_delivery: 'bg-purple-100 text-purple-700 border-purple-200',
      delivered: 'bg-emerald-100 text-emerald-700 border-emerald-200',
      cancelled: 'bg-red-100 text-red-700 border-red-200',
    };
    return map[status] || 'bg-gray-100 text-gray-700 border-gray-200';
  };

  const profileMenuItems = [
    { icon: Receipt, title: "My Orders", subtitle: "Track and view past orders", type: 'orders' },
    { icon: Heart, title: "Favorite Dishes", subtitle: "Your top rated Swahili meals", type: 'favorites' },
    { icon: MapPin, title: "Delivery Addresses", subtitle: "Manage your dropoff locations", type: 'addresses' },
    { icon: HelpCircle, title: "Help & Support", subtitle: "FAQs, chat support, and contact info", type: 'help' },
    { icon: FileText, title: "Terms & Conditions", subtitle: "User agreement and privacy policy", type: 'terms' },
  ];

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

          {/* Profile Quick Links */}
          <div className="space-y-1 pt-2 border-t border-border">
            {profileMenuItems.map((item, idx) => {
              const Icon = item.icon;
              return (
                <button
                  key={idx}
                  onClick={() => openModal(item.type)}
                  className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-muted/50 transition-colors text-left group cursor-pointer"
                >
                  <div className="size-9 rounded-lg bg-primary/5 flex items-center justify-center text-primary shrink-0 group-hover:bg-primary/10 transition-colors">
                    <Icon className="size-4.5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-foreground-dark">{item.title}</p>
                    <p className="text-[10px] text-muted-foreground font-semibold truncate">{item.subtitle}</p>
                  </div>
                  <ChevronRight className="size-4 text-muted-foreground shrink-0" />
                </button>
              );
            })}
          </div>
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

      {/* Modal Overlay */}
      {activeModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white w-full sm:max-w-lg sm:rounded-3xl rounded-t-3xl max-h-[85vh] sm:max-h-[80vh] overflow-hidden flex flex-col shadow-2xl">
            
            {/* Modal Header */}
            <div className="flex items-center justify-between p-5 border-b border-border shrink-0">
              <h3 className="font-heading font-bold text-lg text-foreground-dark">
                {activeModal === 'orders' && 'My Orders'}
                {activeModal === 'favorites' && 'Favorite Dishes'}
                {activeModal === 'addresses' && 'Delivery Addresses'}
                {activeModal === 'help' && 'Help & Support'}
                {activeModal === 'terms' && 'Terms & Conditions'}
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="size-8 rounded-full bg-muted flex items-center justify-center hover:bg-muted/80 transition-colors cursor-pointer"
              >
                <X className="size-4.5 text-muted-foreground" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="flex-1 overflow-y-auto p-5">
              {/* Orders */}
              {activeModal === 'orders' && (
                <div className="space-y-4">
                  {loadingOrders ? (
                    <div className="flex justify-center py-10">
                      <Loader2 className="size-6 text-primary animate-spin" />
                    </div>
                  ) : orders.length === 0 ? (
                    <div className="text-center py-10">
                      <Receipt className="size-12 text-muted-foreground/30 mx-auto mb-3" />
                      <p className="text-sm text-muted-foreground font-semibold">You have no orders yet.</p>
                      <Link href="/search" className="text-xs font-bold text-primary hover:text-secondary mt-2 inline-block">
                        Browse Menu
                      </Link>
                    </div>
                  ) : (
                    orders.map((ord) => {
                      const parsedItems = typeof ord.items === 'string' ? JSON.parse(ord.items) : (ord.items || []);
                      const itemsString = parsedItems.map((item: any) => `${item.name} x${item.quantity}`).join(', ');
                      const statusMap: Record<string, string> = {
                        pending: "Pending",
                        preparing: "Kitchen",
                        in_transit: "In Transit",
                        out_for_delivery: "Out for Delivery",
                        delivered: "Delivered",
                        cancelled: "Cancelled",
                      };
                      const displayStatus = statusMap[ord.status] || ord.status;
                      
                      return (
                        <div key={ord.id} className="bg-card border border-border p-4 rounded-xl space-y-2">
                          <div className="flex items-center justify-between">
                            <span className="font-heading font-bold text-sm text-foreground-dark">
                              Order #{ord.id?.slice(0, 6).toUpperCase() || 'N/A'}
                            </span>
                            <span className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full border ${getStatusColor(ord.status)}`}>
                              {displayStatus}
                            </span>
                          </div>
                          <p className="text-[11px] text-muted-foreground font-semibold">
                            {ord.created_at ? new Date(ord.created_at).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' }) : 'N/A'}
                          </p>
                          <p className="text-xs font-medium text-foreground-dark">{itemsString}</p>
                          <div className="flex items-center justify-between pt-1">
                            <span className="font-heading font-bold text-sm text-primary">
                              TSh {Number(ord.total_price).toLocaleString()}
                            </span>
                            {ord.status === 'delivered' && (
                              <span className="text-[10px] text-emerald-600 font-bold flex items-center gap-1">
                                <CheckCircle2 className="size-3.5" /> Delivered
                              </span>
                            )}
                            {ord.status === 'cancelled' && (
                              <span className="text-[10px] text-red-600 font-bold flex items-center gap-1">
                                <XCircle className="size-3.5" /> Cancelled
                              </span>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              )}

              {/* Favorites */}
              {activeModal === 'favorites' && (
                <div className="space-y-4">
                  {loadingFavorites ? (
                    <div className="flex justify-center py-10">
                      <Loader2 className="size-6 text-primary animate-spin" />
                    </div>
                  ) : favorites.length === 0 ? (
                    <div className="text-center py-10">
                      <Heart className="size-12 text-muted-foreground/30 mx-auto mb-3" />
                      <p className="text-sm text-muted-foreground font-semibold">No favorites added yet.</p>
                      <Link href="/search" className="text-xs font-bold text-primary hover:text-secondary mt-2 inline-block">
                        Discover Dishes
                      </Link>
                    </div>
                  ) : (
                    favorites.map((fav) => (
                      <div key={fav.id} className="flex items-center gap-4 bg-card border border-border p-4 rounded-xl">
                        <div className="size-14 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                          <Star className="size-6" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-bold text-foreground-dark">{fav.menu_items?.name || 'Dish'}</p>
                          <p className="text-[11px] text-muted-foreground font-semibold truncate">{fav.menu_items?.description || ''}</p>
                          <p className="text-xs font-bold text-primary mt-1">
                            TSh {Number(fav.menu_items?.price || 0).toLocaleString()}
                          </p>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* Addresses */}
              {activeModal === 'addresses' && (
                <div className="space-y-4">
                  <div className="bg-card border border-border p-5 rounded-xl">
                    <div className="flex items-center gap-2 mb-3">
                      <MapPin className="size-4.5 text-primary" />
                      <h4 className="font-heading font-bold text-sm text-foreground-dark">Delivery Settings</h4>
                    </div>
                    <p className="text-xs text-muted-foreground font-semibold leading-relaxed mb-4">
                      Choose your delivery region, district, and ward. Your selection will update across Bongo Foodie.
                    </p>
                    <div className="bg-primary/5 border border-primary/20 p-4 rounded-xl">
                      <p className="text-[10px] font-bold uppercase tracking-wider text-primary mb-1">Current Address</p>
                      <p className="text-sm font-bold text-foreground-dark">Dar es Salaam, Tanzania</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Help & Support */}
              {activeModal === 'help' && (
                <div className="space-y-4">
                  <div className="bg-card border border-border p-5 rounded-xl">
                    <div className="flex items-center gap-2 mb-3">
                      <HelpCircle className="size-4.5 text-primary" />
                      <h4 className="font-heading font-bold text-sm text-foreground-dark">Bongo Foodie Support</h4>
                    </div>
                    <p className="text-xs text-muted-foreground font-semibold leading-relaxed mb-4">
                      Need help with an order or have culinary questions? Contact our Dar es Salaam headquarters directly.
                    </p>
                    <div className="space-y-3">
                      <div className="flex items-center gap-3 p-3 bg-white border border-border rounded-xl">
                        <div className="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                          <svg className="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" /></svg>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-foreground-dark">Phone</p>
                          <p className="text-[11px] text-muted-foreground font-semibold">+255 712 345 678</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-white border border-border rounded-xl">
                        <div className="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                          <svg className="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-foreground-dark">Email</p>
                          <p className="text-[11px] text-muted-foreground font-semibold">support@bongofoodie.com</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-white border border-border rounded-xl">
                        <div className="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                          <Clock className="size-4" />
                        </div>
                        <div>
                          <p className="text-xs font-bold text-foreground-dark">Hours</p>
                          <p className="text-[11px] text-muted-foreground font-semibold">Daily: 08:00 AM - 10:00 PM</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Terms & Conditions */}
              {activeModal === 'terms' && (
                <div className="space-y-4">
                  <div className="bg-card border border-border p-5 rounded-xl">
                    <div className="flex items-center gap-2 mb-3">
                      <FileText className="size-4.5 text-primary" />
                      <h4 className="font-heading font-bold text-sm text-foreground-dark">User Service Terms</h4>
                    </div>
                    <div className="space-y-3 text-xs text-muted-foreground font-semibold leading-relaxed">
                      <p>1. Deliveries are estimated and subject to Dar traffic conditions. We strive to deliver within 45-60 minutes.</p>
                      <p>2. Digital payments must settle to admin Till channels. All transactions are processed securely.</p>
                      <p>3. Chef AI suggests custom recipes; please check allergies independently before ordering.</p>
                      <p>4. Cancellations must be made within 10 minutes of placing the order for a full refund.</p>
                      <p>5. Bongo Foodie reserves the right to modify menu items and pricing without prior notice.</p>
                      <p>6. Your privacy is important to us. We do not share your personal data with third parties.</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}