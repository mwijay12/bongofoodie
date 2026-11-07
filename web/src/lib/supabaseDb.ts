import { supabase, isSupabaseConfigured } from './supabase';
import { Category, MenuItem, Order, Profile, UserRole } from '@/types';
import {
  DEMO_PROFILES,
  INITIAL_SHOWCASE_ORDERS,
  SHOWCASE_CATEGORIES,
  SHOWCASE_DISTRICTS,
  SHOWCASE_MENU,
  SHOWCASE_REGIONS,
  SHOWCASE_WARDS,
} from './showcaseData';

export interface GetMenuParams {
  category?: string;
  query?: string;
  limit?: number;
}

const DEMO_SESSION_KEY = 'bongo_demo_session_v2';
const DEMO_ORDERS_KEY = 'bongo_demo_orders_v2';
const DEMO_FAVORITES_KEY = 'bongo_demo_favorites_v2';
const DEMO_MENU_OVERRIDES_KEY = 'bongo_demo_menu_v2';

export const AUTHORIZED_ADMIN_EMAILS = [
  'defoodordering@gmail.com',
  'mwijaydavie@gmail.com',
  'davidbyanmwijage@gmail.com',
];

// ---------------------------------------------------------------------------
// Demo / Showcase Session Helpers (1-click portfolio access)
// ---------------------------------------------------------------------------
export function getDemoSession(): Profile | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(DEMO_SESSION_KEY);
    return raw ? (JSON.parse(raw) as Profile) : null;
  } catch {
    return null;
  }
}

export function startDemoSession(role: UserRole): Profile {
  const profile = DEMO_PROFILES[role] || DEMO_PROFILES.customer;
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(profile));
    window.dispatchEvent(new Event('bongo-auth-changed'));
  }
  return profile;
}

export function saveCustomDemoSession(profile: Profile): Profile {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(profile));
    window.dispatchEvent(new Event('bongo-auth-changed'));
  }
  return profile;
}

export function clearDemoSession(): void {
  if (typeof window !== 'undefined') {
    window.localStorage.removeItem(DEMO_SESSION_KEY);
    window.dispatchEvent(new Event('bongo-auth-changed'));
  }
}

export async function getActiveUserProfile(): Promise<Profile | null> {
  if (isSupabaseConfigured) {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        const u = session.user;
        const { data: profileRow } = await supabase
          .from('profiles')
          .select('id, name, email, phone, role, avatar_url')
          .eq('id', u.id)
          .maybeSingle();

        const inferredRole: UserRole =
          (profileRow?.role as UserRole) ||
          (u.email && AUTHORIZED_ADMIN_EMAILS.includes(u.email) ? 'admin' : 'customer');

        return {
          id: u.id,
          name: profileRow?.name || u.user_metadata?.full_name || u.email || 'Bongo Foodie User',
          email: u.email || '',
          phone: profileRow?.phone || u.user_metadata?.phone || '',
          role: inferredRole,
          avatar_url: profileRow?.avatar_url || u.user_metadata?.avatar_url || '',
          isDemo: false,
        };
      }
    } catch (err) {
      console.warn('[getActiveUserProfile fallback]', err);
    }
  }
  return getDemoSession();
}

// ---------------------------------------------------------------------------
// Local Showcase Storage Helpers
// ---------------------------------------------------------------------------
function getLocalMenu(): MenuItem[] {
  if (typeof window === 'undefined') return SHOWCASE_MENU;
  try {
    const stored = window.localStorage.getItem(DEMO_MENU_OVERRIDES_KEY);
    return stored ? (JSON.parse(stored) as MenuItem[]) : SHOWCASE_MENU;
  } catch {
    return SHOWCASE_MENU;
  }
}

export function saveLocalMenu(items: MenuItem[]): void {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(DEMO_MENU_OVERRIDES_KEY, JSON.stringify(items));
  }
}

export function getLocalOrders(): Order[] {
  if (typeof window === 'undefined') return INITIAL_SHOWCASE_ORDERS;
  try {
    const stored = window.localStorage.getItem(DEMO_ORDERS_KEY);
    if (stored) return JSON.parse(stored) as Order[];
    window.localStorage.setItem(DEMO_ORDERS_KEY, JSON.stringify(INITIAL_SHOWCASE_ORDERS));
    return INITIAL_SHOWCASE_ORDERS;
  } catch {
    return INITIAL_SHOWCASE_ORDERS;
  }
}

export function saveLocalOrders(orders: Order[]): void {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(DEMO_ORDERS_KEY, JSON.stringify(orders));
  }
}

// ---------------------------------------------------------------------------
// Menu & Categories Queries (Fixed Category UUID/Name Filtering + Limit Order!)
// ---------------------------------------------------------------------------
export async function getMenu({ category, query, limit }: GetMenuParams = {}): Promise<MenuItem[]> {
  let items: MenuItem[] = [];

  if (isSupabaseConfigured) {
    try {
      let q = supabase.from('menu').select(`
        id,
        name,
        description,
        image_url,
        price,
        rating,
        rating_count,
        calories,
        protein,
        prep_time_mins,
        categories (
          id,
          name
        )
      `);

      if (query) {
        q = q.ilike('name', `%${query}%`);
      }

      const { data, error } = await q;
      if (error) throw error;

      if (data && data.length > 0) {
        items = data.map((item: any) => ({
          $id: item.id,
          name: item.name,
          description: item.description,
          image_url: item.image_url,
          price: Number(item.price),
          rating: Number(item.rating || 4.8),
          rating_count: Number(item.rating_count || 1),
          calories: item.calories,
          protein: item.protein,
          prep_time_mins: item.prep_time_mins,
          categories: item.categories ? item.categories.name : '',
          _categoryId: item.categories ? item.categories.id : '',
        })) as MenuItem[];
      }
    } catch (error) {
      console.warn('[Supabase getMenu fallback to Showcase Menu]', error);
    }
  }

  if (items.length === 0) {
    items = getLocalMenu().filter((m) =>
      query ? m.name.toLowerCase().includes(query.toLowerCase()) || m.description.toLowerCase().includes(query.toLowerCase()) : true,
    );
  }

  if (category && category.toLowerCase() !== 'all') {
    const normalized = category.toLowerCase();
    items = items.filter((item: any) => {
      const catName = (item.categories || '').toLowerCase();
      const catId = (item._categoryId || '').toLowerCase();
      return catName === normalized || catId === normalized;
    });
  }

  if (limit && limit > 0) {
    items = items.slice(0, limit);
  }

  return items;
}

export async function getCategories(): Promise<Category[]> {
  if (isSupabaseConfigured) {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select('id, name, description')
        .order('sort_order', { ascending: true });

      if (!error && data && data.length > 0) {
        return data.map((cat) => ({
          $id: cat.id,
          name: cat.name,
          description: cat.description,
        }));
      }
    } catch (error) {
      console.warn('[Supabase getCategories fallback]', error);
    }
  }
  return SHOWCASE_CATEGORIES;
}

// ---------------------------------------------------------------------------
// Favorites & Orders (Fixed profile_id + menu relation!)
// ---------------------------------------------------------------------------
export async function toggleFavoriteWeb(userId: string, menuId: string): Promise<boolean> {
  if (isSupabaseConfigured && !userId.startsWith('demo-')) {
    const { data: existing } = await supabase
      .from('favorites')
      .select('id')
      .eq('profile_id', userId)
      .eq('menu_id', menuId)
      .maybeSingle();

    if (existing) {
      await supabase.from('favorites').delete().eq('id', existing.id);
      return false;
    }
    await supabase.from('favorites').insert({ profile_id: userId, menu_id: menuId });
    return true;
  }

  if (typeof window === 'undefined') return false;
  const raw = window.localStorage.getItem(DEMO_FAVORITES_KEY);
  const favIds: string[] = raw ? JSON.parse(raw) : ['menu-nyama-choma', 'menu-pilau-kuku'];
  const exists = favIds.includes(menuId);
  const updated = exists ? favIds.filter((id) => id !== menuId) : [...favIds, menuId];
  window.localStorage.setItem(DEMO_FAVORITES_KEY, JSON.stringify(updated));
  return !exists;
}

export async function getUserFavoritesWeb(userId: string): Promise<MenuItem[]> {
  if (isSupabaseConfigured && !userId.startsWith('demo-')) {
    try {
      const { data, error } = await supabase
        .from('favorites')
        .select(`
          menu_id,
          menu (
            id,
            name,
            description,
            image_url,
            price,
            rating,
            calories,
            protein
          )
        `)
        .eq('profile_id', userId);

      if (!error && data) {
        return data
          .filter((row: any) => row.menu)
          .map((row: any) => ({
            $id: row.menu.id,
            name: row.menu.name,
            description: row.menu.description,
            image_url: row.menu.image_url,
            price: Number(row.menu.price),
            rating: Number(row.menu.rating || 4.8),
            calories: row.menu.calories,
            protein: row.menu.protein,
          }));
      }
    } catch (err) {
      console.warn('[getUserFavoritesWeb fallback]', err);
    }
  }

  if (typeof window === 'undefined') return [];
  const raw = window.localStorage.getItem(DEMO_FAVORITES_KEY);
  const favIds: string[] = raw ? JSON.parse(raw) : ['menu-nyama-choma', 'menu-pilau-kuku'];
  const allMenu = getLocalMenu();
  return allMenu.filter((m) => favIds.includes(m.$id));
}

export async function recordOrderWeb(order: Order): Promise<void> {
  // Always save to local store so Showcase / Waiter / Profile stay in sync immediately
  const existing = getLocalOrders();
  saveLocalOrders([order, ...existing]);

  if (isSupabaseConfigured) {
    try {
      await supabase.from('orders').insert({
        id: order.id,
        profile_id: order.profile_id && !order.profile_id.startsWith('demo-') ? order.profile_id : null,
        table_number: order.table_number || 'Takeaway / Delivery',
        items: JSON.stringify(order.items),
        status: order.status || 'pending',
        total_price: order.total_price,
        payment_method: order.payment_method || 'cash',
        delivery_location: order.delivery_location,
        customer_name: order.customer_name || 'Guest Customer',
        customer_email: order.customer_email || '',
        customer_phone: order.customer_phone || '',
        notes: order.notes || '',
      });
    } catch (err) {
      console.warn('[Supabase order insert fallback saved locally]', err);
    }
  }
}

export async function getOrdersForProfileWeb(userId: string): Promise<Order[]> {
  if (isSupabaseConfigured && !userId.startsWith('demo-')) {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .eq('profile_id', userId)
        .order('created_at', { ascending: false });

      if (!error && data && data.length > 0) {
        return data.map((row: any) => ({
          id: row.id,
          profile_id: row.profile_id,
          table_number: row.table_number,
          items: typeof row.items === 'string' ? JSON.parse(row.items) : row.items || [],
          status: row.status,
          total_price: Number(row.total_price),
          delivery_location: row.delivery_location || 'Dar es Salaam',
          created_at: row.created_at,
          customer_name: row.customer_name,
          customer_email: row.customer_email,
          payment_method: row.payment_method,
        }));
      }
    } catch (err) {
      console.warn('[getOrdersForProfileWeb fallback]', err);
    }
  }

  return getLocalOrders().filter((o) => !o.profile_id || o.profile_id === userId || userId.startsWith('demo-'));
}

// ---------------------------------------------------------------------------
// Tanzania Locations Queries (Self-Contained Fallback + Live Supabase)
// ---------------------------------------------------------------------------
export async function getTzRegions() {
  if (isSupabaseConfigured) {
    try {
      const { data, error } = await supabase
        .from('regions')
        .select('region_name, region_code')
        .order('region_name', { ascending: true });

      if (!error && data && data.length > 0) return data;
    } catch (err) {
      console.warn('[getTzRegions fallback]', err);
    }
  }
  return SHOWCASE_REGIONS;
}

export async function getTzDistricts(regionCode: number) {
  if (isSupabaseConfigured) {
    try {
      const { data, error } = await supabase
        .from('districts')
        .select('district_name, district_code')
        .eq('region_id', regionCode)
        .order('district_name', { ascending: true });

      if (!error && data && data.length > 0) return data;
    } catch (err) {
      console.warn('[getTzDistricts fallback]', err);
    }
  }
  return SHOWCASE_DISTRICTS[regionCode] || [];
}

export async function getTzWards(districtCode: number) {
  if (isSupabaseConfigured) {
    try {
      const { data, error } = await supabase
        .from('wards')
        .select('ward_name, ward_code')
        .eq('district_id', districtCode)
        .order('ward_name', { ascending: true });

      if (!error && data && data.length > 0) return data;
    } catch (err) {
      console.warn('[getTzWards fallback]', err);
    }
  }
  return SHOWCASE_WARDS[districtCode] || [];
}
