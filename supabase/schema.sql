-- ============================================================================
-- BONGO FOODIE v2.0 — COMPLETE PRODUCTION SUPABASE SCHEMA & SEED
-- ============================================================================
-- Run this single file in your Supabase Dashboard -> SQL Editor -> "Run",
-- OR run `npm run supabase:setup` from the repository root.
--
-- Features included:
--   1. Role-based Profiles (customer, waiter, kitchen, admin) + Auth Trigger
--   2. Categories, Customizations, Menu & Menu-Customizations (seeded)
--   3. Secure Menu Reviews + Auto-Calculated Average Rating Trigger & RPC
--   4. Orders (Delivery, Dine-in, Takeaway + Lipa Namba) with Staff/Admin RLS
--   5. Branch Settings, Promotions, Staff Members & Inventory Alerts
--   6. Favorites, Daily Discoveries, Quiz Attempts & User Settings
--   7. Self-Contained Tanzania Locations Hierarchy (Regions -> Districts -> Wards)
--   8. Keep-Alive Heartbeat Table & RPC (`ping_keepalive`) to prevent Free Tier pause
--   9. Storage Buckets (`food-images`, `dishes`, `avatars`) & Storage RLS
--  10. Supabase Realtime Publication for live order & kitchen dispatch updates
-- ============================================================================

create extension if not exists "pgcrypto";

-- ============================================================================
-- 1. PROFILES & ROLE-BASED ACCESS HELPERS
-- ============================================================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null default 'Bongo Foodie User',
  email text,
  phone text default '',
  avatar_url text default '',
  role text not null default 'customer' check (role in ('customer', 'waiter', 'kitchen', 'admin')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Safely ensure v2 columns exist if upgrading from v1
alter table public.profiles add column if not exists phone text default '';
alter table public.profiles add column if not exists role text not null default 'customer';
alter table public.profiles add column if not exists created_at timestamp with time zone default now();

-- Security-definer helpers to avoid RLS recursion on profiles
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select
    coalesce(auth.jwt() ->> 'email', '') in (
      'defoodordering@gmail.com',
      'mwijaydavie@gmail.com',
      'davidbyanmwijage@gmail.com'
    )
    or exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    );
$$;

create or replace function public.is_staff()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select
    public.is_admin()
    or exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role in ('waiter', 'kitchen', 'admin')
    );
$$;

alter table public.profiles enable row level security;

drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
create policy "Public profiles are viewable by everyone."
  on public.profiles for select using (true);

drop policy if exists "Users can insert their own profile." on public.profiles;
create policy "Users can insert their own profile."
  on public.profiles for insert
  with check ((select auth.uid()) = id or public.is_admin());

drop policy if exists "Users can update their own profile." on public.profiles;
create policy "Users can update their own profile."
  on public.profiles for update
  using ((select auth.uid()) = id or public.is_admin())
  with check (
    public.is_admin()
    or (
      (select auth.uid()) = id
      and role = coalesce((select p.role from public.profiles p where p.id = auth.uid()), 'customer')
    )
  );

-- Auto-create profile row when a user signs up via Supabase Auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  assigned_role text := 'customer';
begin
  if coalesce(new.email, '') in (
    'defoodordering@gmail.com',
    'mwijaydavie@gmail.com',
    'davidbyanmwijage@gmail.com'
  ) then
    assigned_role := 'admin';
  end if;

  insert into public.profiles (id, name, email, phone, avatar_url, role, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Bongo Foodie User'),
    new.email,
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', ''),
    assigned_role,
    now()
  )
  on conflict (id) do update
  set
    name = excluded.name,
    email = excluded.email,
    phone = case when excluded.phone <> '' then excluded.phone else public.profiles.phone end,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================================
-- 2. CATEGORIES
-- ============================================================================
create table if not exists public.categories (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  description text,
  sort_order integer default 0,
  created_at timestamp with time zone default now()
);

alter table public.categories add column if not exists sort_order integer default 0;
alter table public.categories enable row level security;

drop policy if exists "Categories are viewable by everyone" on public.categories;
create policy "Categories are viewable by everyone"
  on public.categories for select using (true);

drop policy if exists "Admins can manage categories" on public.categories;
create policy "Admins can manage categories"
  on public.categories for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- 3. CUSTOMIZATIONS (Toppings, Sides & Extras)
-- ============================================================================
create table if not exists public.customizations (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  price numeric not null check (price >= 0),
  type text not null default 'topping',
  created_at timestamp with time zone default now()
);

alter table public.customizations enable row level security;

drop policy if exists "Customizations are viewable by everyone" on public.customizations;
create policy "Customizations are viewable by everyone"
  on public.customizations for select using (true);

drop policy if exists "Admins can manage customizations" on public.customizations;
create policy "Admins can manage customizations"
  on public.customizations for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- 4. MENU ITEMS & MENU-CUSTOMIZATIONS
-- ============================================================================
create table if not exists public.menu (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  description text not null,
  image_url text not null,
  price numeric not null check (price >= 0),
  rating numeric(3,2) default 4.8,
  rating_count integer default 12,
  calories integer default 520,
  protein integer default 24,
  prep_time_mins integer default 20,
  is_available boolean default true,
  category_id uuid references public.categories(id) on delete set null,
  created_at timestamp with time zone default now()
);

alter table public.menu add column if not exists rating_count integer default 12;
alter table public.menu add column if not exists prep_time_mins integer default 20;
alter table public.menu add column if not exists is_available boolean default true;

alter table public.menu add column if not exists spice_level smallint check (spice_level between 0 and 5), add column if not exists ingredients text[] not null default '{}', add column if not exists allergens text[] not null default '{}', add column if not exists fun_fact_en text, add column if not exists fun_fact_sw text;

create index if not exists idx_menu_category_id on public.menu(category_id);

alter table public.menu enable row level security;

-- Remove old insecure policy ("Anyone can update menu items")
drop policy if exists "Anyone can update menu items" on public.menu;
drop policy if exists "Menu items are viewable by everyone" on public.menu;
create policy "Menu items are viewable by everyone"
  on public.menu for select using (true);

drop policy if exists "Admins can insert menu items" on public.menu;
create policy "Admins can insert menu items"
  on public.menu for insert
  with check (public.is_admin());

drop policy if exists "Admins can update menu items" on public.menu;
create policy "Admins can update menu items"
  on public.menu for update
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete menu items" on public.menu;
create policy "Admins can delete menu items"
  on public.menu for delete
  using (public.is_admin());

create table if not exists public.menu_customizations (
  id uuid default gen_random_uuid() primary key,
  menu_id uuid references public.menu(id) on delete cascade not null,
  customization_id uuid references public.customizations(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (menu_id, customization_id)
);

alter table public.menu_customizations enable row level security;

drop policy if exists "Menu customizations are viewable by everyone" on public.menu_customizations;
create policy "Menu customizations are viewable by everyone"
  on public.menu_customizations for select using (true);

drop policy if exists "Admins can manage menu customizations" on public.menu_customizations;
create policy "Admins can manage menu customizations"
  on public.menu_customizations for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- 5. MENU REVIEWS & SAFE RATING AGGREGATION RPC
-- ============================================================================
create table if not exists public.menu_reviews (
  id uuid default gen_random_uuid() primary key,
  menu_id uuid references public.menu(id) on delete cascade not null,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  rating integer not null check (rating between 1 and 5),
  comment text default '',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique (menu_id, profile_id)
);

alter table public.menu_reviews enable row level security;

drop policy if exists "Reviews are viewable by everyone" on public.menu_reviews;
create policy "Reviews are viewable by everyone"
  on public.menu_reviews for select using (true);

drop policy if exists "Authenticated users can upsert own reviews" on public.menu_reviews;
create policy "Authenticated users can upsert own reviews"
  on public.menu_reviews for insert
  with check (auth.uid() = profile_id);

drop policy if exists "Users can update own reviews" on public.menu_reviews;
create policy "Users can update own reviews"
  on public.menu_reviews for update
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

create or replace function public.sync_menu_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_menu uuid := coalesce(new.menu_id, old.menu_id);
  avg_score numeric(3,2);
  total_reviews integer;
begin
  select
    round(avg(rating)::numeric, 1),
    count(*)
  into avg_score, total_reviews
  from public.menu_reviews
  where menu_id = target_menu;

  update public.menu
  set
    rating = coalesce(avg_score, 4.8),
    rating_count = greatest(total_reviews, 1)
  where id = target_menu;

  return coalesce(new, old);
end;
$$;

drop trigger if exists on_menu_review_changed on public.menu_reviews;
create trigger on_menu_review_changed
  after insert or update or delete on public.menu_reviews
  for each row execute procedure public.sync_menu_rating();

-- Convenient RPC for mobile & web clients to rate a dish cleanly
create or replace function public.rate_menu_item(
  p_menu_id uuid,
  p_rating integer,
  p_comment text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  updated_rating numeric;
  updated_count integer;
begin
  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5';
  end if;

  if uid is not null then
    -- Ensure profile row exists
    insert into public.profiles (id, name, email)
    select uid, 'Bongo Foodie User', coalesce(auth.jwt() ->> 'email', '')
    where not exists (select 1 from public.profiles where id = uid);

    insert into public.menu_reviews (menu_id, profile_id, rating, comment, updated_at)
    values (p_menu_id, uid, p_rating, coalesce(p_comment, ''), now())
    on conflict (menu_id, profile_id) do update
    set
      rating = excluded.rating,
      comment = excluded.comment,
      updated_at = now();
  else
    -- Weighted incremental average for anonymous demo ratings without exposing raw table updates
    update public.menu
    set
      rating = round(((coalesce(rating, 4.8) * greatest(coalesce(rating_count, 5), 1) + p_rating) / (greatest(coalesce(rating_count, 5), 1) + 1))::numeric, 1),
      rating_count = greatest(coalesce(rating_count, 5), 1) + 1
    where id = p_menu_id;
  end if;

  select rating, rating_count
  into updated_rating, updated_count
  from public.menu
  where id = p_menu_id;

  return jsonb_build_object(
    'menu_id', p_menu_id,
    'rating', coalesce(updated_rating, p_rating),
    'rating_count', coalesce(updated_count, 1)
  );
end;
$$;

grant execute on function public.rate_menu_item(uuid, integer, text) to anon, authenticated;

-- ============================================================================
-- 6. ORDERS
-- ============================================================================
create table if not exists public.orders (
  id text primary key,
  profile_id uuid references public.profiles(id) on delete set null,
  table_number text default 'Delivery',
  order_type text default 'delivery' check (order_type in ('delivery', 'dine_in', 'takeaway')),
  items text not null, -- JSON array string for full backward compatibility
  status text default 'pending' check (status in ('pending', 'preparing', 'ready', 'in_transit', 'delivered', 'cancelled')),
  subtotal numeric default 0,
  delivery_fee numeric default 3000,
  discount_amount numeric default 0,
  total_price numeric not null,
  payment_method text default 'cash' check (payment_method in ('cash', 'lipanamba')),
  payment_reference text default '',
  delivery_location text default 'Dar es Salaam, Tanzania',
  customer_name text default 'Guest Customer',
  customer_email text default '',
  customer_phone text default '',
  notes text default '',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.orders add column if not exists order_type text default 'delivery';
alter table public.orders add column if not exists subtotal numeric default 0;
alter table public.orders add column if not exists delivery_fee numeric default 3000;
alter table public.orders add column if not exists discount_amount numeric default 0;
alter table public.orders add column if not exists payment_method text default 'cash';
alter table public.orders add column if not exists payment_reference text default '';
alter table public.orders add column if not exists customer_phone text default '';
alter table public.orders add column if not exists notes text default '';
alter table public.orders add column if not exists updated_at timestamp with time zone default now();

create index if not exists idx_orders_profile_id on public.orders(profile_id);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_created_at on public.orders(created_at desc);

alter table public.orders enable row level security;

drop policy if exists "Everyone can insert orders." on public.orders;
create policy "Everyone can insert orders."
  on public.orders for insert with check (true);

drop policy if exists "Users can view their own orders or Admin can view all." on public.orders;
drop policy if exists "Users or Staff can view orders" on public.orders;
create policy "Users or Staff can view orders"
  on public.orders for select
  using (
    (select auth.uid()) = profile_id
    or public.is_staff()
  );

drop policy if exists "Users can update their own orders or Admin can update all." on public.orders;
drop policy if exists "Users or Staff can update orders" on public.orders;
create policy "Users or Staff can update orders"
  on public.orders for update
  using (
    (select auth.uid()) = profile_id
    or public.is_staff()
  );

-- ============================================================================
-- 7. BRANCH SETTINGS, PROMOTIONS, STAFF & INVENTORY ALERTS
-- ============================================================================
create table if not exists public.settings (
  id text primary key default 'branch_settings',
  restaurant_name text default 'Bongo Foodie',
  branch_address text default 'Kijitonyama Branch, Dar es Salaam',
  phone text default '+255 712 345 678',
  mpesa_till text default '556677',
  tigo_till text default '223344',
  airtel_till text default '889900',
  halo_till text default '112233',
  nmb_account text default '9900112233',
  crdb_account text default '8877665544',
  logo text default '',
  delivery_fee numeric default 3000,
  promo_code text default 'KARIBU2000',
  promo_discount numeric default 2000,
  promo_active boolean default true,
  updated_at timestamp with time zone default now()
);

alter table public.settings add column if not exists delivery_fee numeric default 3000;
alter table public.settings add column if not exists promo_code text default 'KARIBU2000';
alter table public.settings add column if not exists promo_discount numeric default 2000;
alter table public.settings add column if not exists promo_active boolean default true;

alter table public.settings enable row level security;

drop policy if exists "Settings are viewable by everyone" on public.settings;
create policy "Settings are viewable by everyone"
  on public.settings for select using (true);

drop policy if exists "Only admin can update settings" on public.settings;
create policy "Only admin can update settings"
  on public.settings for update using (public.is_admin());

drop policy if exists "Only admin can insert settings" on public.settings;
create policy "Only admin can insert settings"
  on public.settings for insert with check (public.is_admin());

insert into public.settings (
  id, restaurant_name, branch_address, phone,
  mpesa_till, tigo_till, airtel_till, halo_till, nmb_account, crdb_account,
  logo, delivery_fee, promo_code, promo_discount, promo_active
)
values (
  'branch_settings', 'Bongo Foodie', 'Kijitonyama Branch, Dar es Salaam', '+255 712 345 678',
  '556677', '223344', '889900', '112233', '9900112233', '8877665544',
  '', 3000, 'KARIBU2000', 2000, true
)
on conflict (id) do nothing;

-- Promotional Campaigns Table (synced across Mobile & Web)
create table if not exists public.promotions (
  id uuid default gen_random_uuid() primary key,
  title text unique not null,
  subtitle text not null,
  discount_badge text not null,
  promo_code text default 'KARIBU2000',
  bg_hex text default '#F6821F',
  image_key text default 'nyamaChoma',
  is_active boolean default true,
  sort_order integer default 0,
  created_at timestamp with time zone default now()
);

alter table public.promotions enable row level security;

drop policy if exists "Promotions are viewable by everyone" on public.promotions;
create policy "Promotions are viewable by everyone"
  on public.promotions for select using (true);

drop policy if exists "Admins can manage promotions" on public.promotions;
create policy "Admins can manage promotions"
  on public.promotions for all
  using (public.is_admin())
  with check (public.is_admin());

-- Staff Directory Table
create table if not exists public.staff_members (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  role text not null default 'Waiter' check (role in ('Manager', 'Waiter', 'Delivery', 'Kitchen', 'Security', 'Supply')),
  status text not null default 'active' check (status in ('active', 'offline')),
  email text unique,
  phone text default '',
  created_at timestamp with time zone default now()
);

alter table public.staff_members enable row level security;

drop policy if exists "Staff directory viewable by staff" on public.staff_members;
create policy "Staff directory viewable by staff"
  on public.staff_members for select using (public.is_staff());

drop policy if exists "Admins manage staff directory" on public.staff_members;
create policy "Admins manage staff directory"
  on public.staff_members for all
  using (public.is_admin())
  with check (public.is_admin());

-- Kitchen Inventory Alerts Table
create table if not exists public.inventory_alerts (
  id uuid default gen_random_uuid() primary key,
  item text not null,
  status text not null default 'low' check (status in ('low', 'out_of_stock', 'good')),
  reported_by text default 'Kitchen Team',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.inventory_alerts enable row level security;

drop policy if exists "Staff can view inventory alerts" on public.inventory_alerts;
create policy "Staff can view inventory alerts"
  on public.inventory_alerts for select using (public.is_staff());

drop policy if exists "Staff can insert or update inventory alerts" on public.inventory_alerts;
create policy "Staff can insert or update inventory alerts"
  on public.inventory_alerts for all
  using (public.is_staff())
  with check (public.is_staff());

-- ============================================================================
-- 8. FAVORITES, DAILY DISCOVERIES, QUIZ ATTEMPTS & USER SETTINGS
-- ============================================================================
create table if not exists public.favorites (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  menu_id uuid references public.menu(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (profile_id, menu_id)
);

alter table public.favorites enable row level security;

drop policy if exists "Users can view their own favorites" on public.favorites;
create policy "Users can view their own favorites"
  on public.favorites for select using (auth.uid() = profile_id);

drop policy if exists "Users can insert their own favorites" on public.favorites;
create policy "Users can insert their own favorites"
  on public.favorites for insert with check (auth.uid() = profile_id);

drop policy if exists "Users can delete their own favorites" on public.favorites;
create policy "Users can delete their own favorites"
  on public.favorites for delete using (auth.uid() = profile_id);

create table if not exists public.daily_discoveries (
  id uuid default gen_random_uuid() primary key,
  title text unique not null,
  description text not null,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.daily_discoveries enable row level security;

drop policy if exists "Daily discoveries are viewable by everyone" on public.daily_discoveries;
create policy "Daily discoveries are viewable by everyone"
  on public.daily_discoveries for select using (true);

drop policy if exists "Only admin can insert daily discoveries" on public.daily_discoveries;
create policy "Only admin can insert daily discoveries"
  on public.daily_discoveries for insert with check (public.is_admin());

drop policy if exists "Only admin can update daily discoveries" on public.daily_discoveries;
create policy "Only admin can update daily discoveries"
  on public.daily_discoveries for update using (public.is_admin());

drop policy if exists "Only admin can delete daily discoveries" on public.daily_discoveries;
create policy "Only admin can delete daily discoveries"
  on public.daily_discoveries for delete using (public.is_admin());

create table if not exists public.quiz_attempts (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  quiz_date date default current_date not null,
  is_correct boolean default false,
  created_at timestamp with time zone default now(),
  unique (profile_id, quiz_date)
);

alter table public.quiz_attempts enable row level security;

drop policy if exists "Users can view their own quiz attempts" on public.quiz_attempts;
create policy "Users can view their own quiz attempts"
  on public.quiz_attempts for select using (auth.uid() = profile_id);

drop policy if exists "Users can insert their own quiz attempts" on public.quiz_attempts;
create policy "Users can insert their own quiz attempts"
  on public.quiz_attempts for insert with check (auth.uid() = profile_id);

create table if not exists public.user_settings (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null unique,
  push_notifications boolean default true,
  email_notifications boolean default true,
  sms_notifications boolean default false,
  order_updates boolean default true,
  promotional_offers boolean default true,
  preferred_language text default 'en' check (preferred_language in ('en', 'sw')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.user_settings add column if not exists preferred_language text default 'en';
alter table public.user_settings enable row level security;

drop policy if exists "Users can view their own settings" on public.user_settings;
create policy "Users can view their own settings"
  on public.user_settings for select using (auth.uid() = profile_id);

drop policy if exists "Users can insert their own settings" on public.user_settings;
create policy "Users can insert their own settings"
  on public.user_settings for insert with check (auth.uid() = profile_id);

drop policy if exists "Users can update their own settings" on public.user_settings;
create policy "Users can update their own settings"
  on public.user_settings for update using (auth.uid() = profile_id);

-- ============================================================================
-- 9. SELF-CONTAINED TANZANIA LOCATIONS (Regions -> Districts -> Wards)
-- ============================================================================
create table if not exists public.regions (
  region_code integer primary key,
  region_name text not null
);

create table if not exists public.districts (
  district_code integer primary key,
  district_name text not null,
  region_id integer references public.regions(region_code) on delete cascade not null
);

create table if not exists public.wards (
  ward_code integer primary key,
  ward_name text not null,
  district_id integer references public.districts(district_code) on delete cascade not null
);

create index if not exists idx_districts_region_id on public.districts(region_id);
create index if not exists idx_wards_district_id on public.wards(district_id);

alter table public.regions enable row level security;
alter table public.districts enable row level security;
alter table public.wards enable row level security;

drop policy if exists "Regions are viewable by everyone" on public.regions;
create policy "Regions are viewable by everyone" on public.regions for select using (true);

drop policy if exists "Districts are viewable by everyone" on public.districts;
create policy "Districts are viewable by everyone" on public.districts for select using (true);

drop policy if exists "Wards are viewable by everyone" on public.wards;
create policy "Wards are viewable by everyone" on public.wards for select using (true);

-- ============================================================================
-- 10. KEEP-ALIVE HEARTBEAT TABLE & RPC (PREVENTS SUPABASE FREE-TIER PAUSE!)
-- ============================================================================
create table if not exists public.keepalive_heartbeat (
  id integer primary key default 1 check (id = 1),
  ping_count bigint not null default 0,
  last_source text not null default 'initial_migration',
  last_pinged_at timestamp with time zone not null default now()
);

alter table public.keepalive_heartbeat enable row level security;

drop policy if exists "Keepalive heartbeat readable by all" on public.keepalive_heartbeat;
create policy "Keepalive heartbeat readable by all"
  on public.keepalive_heartbeat for select using (true);

insert into public.keepalive_heartbeat (id, ping_count, last_source, last_pinged_at)
values (1, 1, 'initial_migration', now())
on conflict (id) do nothing;

-- Callable via `POST /rest/v1/rpc/ping_keepalive` using ONLY the public anon key!
-- Performs a real Postgres write + read so Supabase registers active DB usage.
create or replace function public.ping_keepalive(p_source text default 'cron')
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result_row public.keepalive_heartbeat;
begin
  insert into public.keepalive_heartbeat (id, ping_count, last_source, last_pinged_at)
  values (1, 1, coalesce(p_source, 'cron'), now())
  on conflict (id) do update
  set
    ping_count = public.keepalive_heartbeat.ping_count + 1,
    last_source = coalesce(p_source, 'cron'),
    last_pinged_at = now()
  returning * into result_row;

  return jsonb_build_object(
    'ok', true,
    'project', 'bongo-foodie',
    'ping_count', result_row.ping_count,
    'last_source', result_row.last_source,
    'last_pinged_at', result_row.last_pinged_at
  );
end;
$$;

grant execute on function public.ping_keepalive(text) to anon, authenticated;

-- ============================================================================
-- 11. STORAGE BUCKETS & POLICIES (`food-images`, `dishes`, `avatars`)
-- ============================================================================
insert into storage.buckets (id, name, public)
values
  ('food-images', 'food-images', true),
  ('dishes', 'dishes', true),
  ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "Public read access on Bongo Foodie buckets" on storage.objects;
create policy "Public read access on Bongo Foodie buckets"
  on storage.objects for select
  using (bucket_id in ('food-images', 'dishes', 'avatars'));

drop policy if exists "Authenticated users can upload avatars" on storage.objects;
create policy "Authenticated users can upload avatars"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.role() = 'authenticated');

drop policy if exists "Authenticated users can update own avatars" on storage.objects;
create policy "Authenticated users can update own avatars"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.role() = 'authenticated');

drop policy if exists "Admins can upload food and dish images" on storage.objects;
create policy "Admins can upload food and dish images"
  on storage.objects for all
  using (bucket_id in ('food-images', 'dishes') and public.is_admin())
  with check (bucket_id in ('food-images', 'dishes') and public.is_admin());

-- ============================================================================
-- 12. REALTIME PUBLICATION (Live Order & Kitchen Dispatch Updates)
-- ============================================================================
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.orders;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.promotions;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.inventory_alerts;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.settings;
    exception when duplicate_object then null;
    end;
  end if;
end $$;

-- ============================================================================
-- 13. SEED AUTHENTIC SWAHILI MENU, PROMOTIONS, DISCOVERIES & TZ LOCATIONS
-- ============================================================================

-- 13A. Categories
insert into public.categories (name, description, sort_order) values
  ('Swahili Bites', 'Traditional East African street starters & coastal snacks', 1),
  ('Nyama Choma', 'Charcoal flame-grilled signature Tanzanian meats', 2),
  ('Rice & Pilau', 'Zanzibar spice-infused pilau, biryani & coconut rice', 3),
  ('Traditional Stews', 'Slow-simmered tui la nazi curries & chapati pairings', 4),
  ('Gourmet Specials', 'Chef fusion burgers & wood-fired Swahili pizzas', 5),
  ('Vinywaji', 'Fresh tropical juices, spiced chai & chilled sodas', 6)
on conflict (name) do update
set description = excluded.description, sort_order = excluded.sort_order;

-- 13B. Customizations
insert into public.customizations (name, price, type) values
  ('Kachumbari Extra', 1000, 'topping'),
  ('Pili Pili Kali', 500, 'topping'),
  ('Ndimu (Fresh Lime)', 300, 'topping'),
  ('Ndizi Mzuzu Extra', 1500, 'topping'),
  ('Avocado Slices', 1000, 'topping'),
  ('Cheese Slice', 1200, 'topping'),
  ('Ugali Kipande', 1500, 'side'),
  ('Chips Kaanga', 2500, 'side'),
  ('Chapati Moja', 1000, 'side'),
  ('Mchicha wa Nazi', 1500, 'side'),
  ('Stoney Tangawizi', 1500, 'drink'),
  ('Juisi ya Passion', 2500, 'drink'),
  ('Chai ya Masala', 1500, 'drink'),
  ('Maji ya Kilimanjaro', 1000, 'drink')
on conflict (name) do update
set price = excluded.price, type = excluded.type;

-- 13C. Menu Items (Local-first keys + verified gourmet food photography)
insert into public.menu (name, description, image_url, price, rating, rating_count, calories, protein, prep_time_mins, category_id)
values
  (
    'Chipsi Mayai',
    'Iconic Dar es Salaam golden French fry omelette served hot with fresh tomato-onion kachumbari and house tamarind pili pili.',
    'chipsiMayai',
    5500, 4.9, 84, 580, 18, 12,
    (select id from public.categories where name = 'Swahili Bites')
  ),
  (
    'Nyama Choma & Ugali',
    'Charcoal-grilled tender beef ribs basted in ginger-lime marinade, paired with warm sembe ugali, mchicha wa nazi, and kachumbari.',
    'nyamaChoma',
    13500, 4.9, 126, 780, 46, 25,
    (select id from public.categories where name = 'Nyama Choma')
  ),
  (
    'Pilau ya Kuku',
    'Fragrant Zanzibar spiced basmati rice slow-cooked with caramelized onions, whole cardamom, cloves, tender kuku kienyeji, and kachumbari.',
    'pilauYaKuku',
    10000, 4.8, 97, 640, 32, 20,
    (select id from public.categories where name = 'Rice & Pilau')
  ),
  (
    'Samaki wa Kupaka',
    'Charcoal-seared Indian Ocean snapper simmered in rich Tui la Nazi (fresh coconut cream), turmeric, garlic, and green mango tamarind glaze.',
    'samakiWaKupaka',
    15000, 4.9, 73, 690, 40, 25,
    (select id from public.categories where name = 'Traditional Stews')
  ),
  (
    'Mishkaki ya Ng''ombe',
    'Four smoky beef tenderloin skewers marinated overnight in papaya, crushed ginger, garlic, and Zanzibar black pepper over glowing mkaa.',
    'mishkakiYaNgombe',
    7500, 4.7, 64, 460, 35, 15,
    (select id from public.categories where name = 'Nyama Choma')
  ),
  (
    'Wali wa Nazi na Maharage',
    'Creamy coconut-steamed rice paired with velvety red kidney beans braised in fresh coconut milk and sweet coastal cardamom.',
    'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&auto=format&fit=crop&q=80',
    6000, 4.6, 42, 540, 16, 15,
    (select id from public.categories where name = 'Rice & Pilau')
  ),
  (
    'Mchuzi wa Kuku na Chapati',
    'Rich coastal chicken coconut curry served with two flaky pan-layered golden chapatis brushed with ghee.',
    'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=800&auto=format&fit=crop&q=80',
    9500, 4.8, 58, 660, 30, 18,
    (select id from public.categories where name = 'Traditional Stews')
  ),
  (
    'Ndizi Mzuzu Kaanga',
    'Caramelized ripe sweet plantain medallions lightly spiced with black pepper and sea salt, served with pili pili ya ukwaju.',
    'fries',
    4000, 4.6, 39, 320, 4, 10,
    (select id from public.categories where name = 'Swahili Bites')
  ),
  (
    'Bongo Pili-Pili Smash Burger',
    'Double flame-seared Tanzanian beef patty, melted cheddar, smoky pili-pili aioli, avocado, and crispy onions on a toasted brioche bun.',
    'burgerOne',
    11000, 4.8, 51, 740, 38, 15,
    (select id from public.categories where name = 'Gourmet Specials')
  ),
  (
    'Zanzibar Spice Wood-Fired Pizza',
    'Artisan sourdough crust topped with spiced suki beef, mozzarella, roasted sweet peppers, red onions, and fresh coriander.',
    'pizzaOne',
    16000, 4.8, 45, 860, 36, 22,
    (select id from public.categories where name = 'Gourmet Specials')
  ),
  (
    'Juisi ya Passion & Embe Baridi',
    'Freshly pressed Morogoro passion fruit and ripe coastal mango juice served chilled with a hint of fresh mint.',
    'orangeJuiceIcon',
    3500, 4.9, 68, 160, 2, 5,
    (select id from public.categories where name = 'Vinywaji')
  ),
  (
    'Stoney Tangawizi Baridi',
    'Ice-cold East African fiery ginger soda — the undisputed companion to hot Nyama Choma and Mishkaki.',
    'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800&auto=format&fit=crop&q=80',
    2000, 4.8, 91, 140, 0, 2,
    (select id from public.categories where name = 'Vinywaji')
  )
on conflict (name) do update
set
  description = excluded.description,
  image_url = excluded.image_url,
  price = excluded.price,
  calories = excluded.calories,
  protein = excluded.protein,
  prep_time_mins = excluded.prep_time_mins,
  category_id = excluded.category_id;

-- 13C2. Premium dish-detail seed values (idempotent, admin setup path only)
with menu_details(name, spice_level, ingredients, allergens, fun_fact_en, fun_fact_sw) as (
  values
  (
    'Chipsi Mayai',
    2,
    array['French fries', 'eggs', 'tomatoes', 'onions', 'tamarind', 'chili']::text[],
    array['egg']::text[],
    'Chipsi mayai combines fried potatoes with eggs in one omelette.',
    'Chipsi mayai huchanganya viazi vya kukaanga na mayai katika omeleti moja.'
  ),
  (
    'Nyama Choma & Ugali',
    2,
    array['beef', 'maize flour', 'spinach', 'coconut milk', 'tomatoes', 'onions', 'ginger', 'lime']::text[],
    array['coconut']::text[],
    'Ugali is a firm maize-meal porridge often served with grilled meat.',
    'Ugali ni uji mzito wa unga wa mahindi unaotolewa mara nyingi na nyama ya kuchoma.'
  ),
  (
    'Pilau ya Kuku',
    3,
    array['basmati rice', 'chicken', 'onions', 'cardamom', 'cloves', 'tomatoes']::text[],
    '{}'::text[],
    'Pilau is rice cooked with whole spices such as cardamom and cloves.',
    'Pilau ni wali unaopikwa na viungo vizima kama iliki na karafuu.'
  ),
  (
    'Samaki wa Kupaka',
    2,
    array['snapper', 'coconut cream', 'turmeric', 'garlic', 'mango', 'tamarind']::text[],
    array['fish', 'coconut']::text[],
    'Samaki wa kupaka is fish simmered in coconut cream or coconut milk.',
    'Samaki wa kupaka hupikwa kwa tui la nazi au maziwa ya nazi.'
  ),
  (
    'Mishkaki ya Ng''ombe',
    3,
    array['beef', 'papaya', 'ginger', 'garlic', 'black pepper']::text[],
    '{}'::text[],
    'Mishkaki are small pieces of meat grilled on skewers.',
    'Mishkaki ni vipande vidogo vya nyama vinavyochomwa kwenye vijiti.'
  ),
  (
    'Wali wa Nazi na Maharage',
    1,
    array['rice', 'coconut milk', 'red kidney beans', 'cardamom']::text[],
    array['coconut']::text[],
    'Wali wa nazi is rice cooked with coconut milk.',
    'Wali wa nazi hupikwa kwa tui la nazi.'
  ),
  (
    'Mchuzi wa Kuku na Chapati',
    2,
    array['chicken', 'coconut milk', 'wheat flour', 'ghee', 'spices']::text[],
    array['gluten', 'milk']::text[],
    'Chapati is a layered flatbread cooked on a hot pan.',
    'Chapati ni mkate bapa wenye tabaka unaopikwa kwenye sufuria moto.'
  ),
  (
    'Ndizi Mzuzu Kaanga',
    2,
    array['plantain', 'black pepper', 'sea salt', 'tamarind']::text[],
    '{}'::text[],
    'Ripe plantains are naturally sweet before they are fried.',
    'Ndizi mzuzu mbivu huwa na utamu wa asili kabla ya kukaangwa.'
  ),
  (
    'Bongo Pili-Pili Smash Burger',
    3,
    array['beef', 'cheddar', 'aioli', 'avocado', 'onions', 'brioche bun']::text[],
    array['gluten', 'egg', 'milk']::text[],
    'A smash burger is made by pressing the patty flat on a hot surface.',
    'Smash burger hutengenezwa kwa kubana nyama iliyo bapa kwenye uso moto.'
  ),
  (
    'Zanzibar Spice Wood-Fired Pizza',
    2,
    array['sourdough crust', 'beef', 'mozzarella', 'sweet peppers', 'red onions', 'coriander']::text[],
    array['gluten', 'milk']::text[],
    'Sourdough crust is made with a fermented flour-and-water starter.',
    'Ukoko wa sourdough hutengenezwa kwa chachu ya unga na maji iliyochachuka.'
  ),
  (
    'Juisi ya Passion & Embe Baridi',
    0,
    array['passion fruit', 'mango', 'mint']::text[],
    '{}'::text[],
    'Passion fruit and mango grow in tropical regions.',
    'Matunda ya passion na embe hukua katika maeneo ya kitropiki.'
  ),
  (
    'Stoney Tangawizi Baridi',
    1,
    array['ginger soda']::text[],
    '{}'::text[],
    'Ginger soda gets its sharp taste from ginger.',
    'Soda ya tangawizi hupata ladha yake kali kutoka kwa tangawizi.'
  )
)
update public.menu as m
set
  spice_level = d.spice_level,
  ingredients = d.ingredients,
  allergens = d.allergens,
  fun_fact_en = d.fun_fact_en,
  fun_fact_sw = d.fun_fact_sw
from menu_details as d
where m.name = d.name;

-- 13D. Link Menu Customizations Automatically
insert into public.menu_customizations (menu_id, customization_id)
select m.id, c.id
from public.menu m
join public.customizations c on (
  (m.name in ('Chipsi Mayai', 'Nyama Choma & Ugali', 'Mishkaki ya Ng''ombe') and c.name in ('Kachumbari Extra', 'Pili Pili Kali', 'Ndimu (Fresh Lime)', 'Ugali Kipande', 'Stoney Tangawizi'))
  or (m.name in ('Pilau ya Kuku', 'Wali wa Nazi na Maharage') and c.name in ('Kachumbari Extra', 'Pili Pili Kali', 'Avocado Slices', 'Ndizi Mzuzu Extra', 'Juisi ya Passion'))
  or (m.name in ('Samaki wa Kupaka', 'Mchuzi wa Kuku na Chapati') and c.name in ('Chapati Moja', 'Mchicha wa Nazi', 'Ndimu (Fresh Lime)', 'Ugali Kipande', 'Juisi ya Passion'))
  or (m.name in ('Bongo Pili-Pili Smash Burger', 'Zanzibar Spice Wood-Fired Pizza', 'Ndizi Mzuzu Kaanga') and c.name in ('Cheese Slice', 'Avocado Slices', 'Chips Kaanga', 'Pili Pili Kali', 'Stoney Tangawizi'))
)
on conflict (menu_id, customization_id) do nothing;

-- 13E. Promotional Campaigns
insert into public.promotions (title, subtitle, discount_badge, promo_code, bg_hex, image_key, is_active, sort_order)
values
  ('KARIBU BONGO FEAST', 'Save TSh 2,000 on any Swahili main dish with code KARIBU2000', 'TSh 2,000 OFF', 'KARIBU2000', '#F6821F', 'nyamaChoma', true, 1),
  ('IJUMAA PILAU & JUICE', 'Zanzibar Pilau ya Kuku + Fresh Passion Mango Juice combo', '15% OFF', 'KARIBU2000', '#0F5132', 'pilauYaKuku', true, 2),
  ('WEEKEND PIZZA & BURGER', 'Wood-fired Zanzibar Pizza & Smash Burger family deal', '20% OFF', 'KARIBU2000', '#181C2E', 'pizzaOne', true, 3)
on conflict (title) do update
set
  subtitle = excluded.subtitle,
  discount_badge = excluded.discount_badge,
  bg_hex = excluded.bg_hex,
  image_key = excluded.image_key,
  sort_order = excluded.sort_order;

-- 13F. Daily Discoveries
insert into public.daily_discoveries (title, description) values
  ('Zanzibar Spice Capital', 'Zanzibar (Unguja) is nicknamed the ''Spice Island'' because it remains one of the world''s top producers of aromatic Cloves (Karafuu), Cinnamon (Mdalasini), and Nutmeg (Kungumanga).'),
  ('Bongo Foodie Sourcing', 'We source 100% of our organic vegetables, Morogoro rice, and free-range poultry directly from Tanzanian smallholder farms.'),
  ('National Street Icon', 'Chipsi Mayai started at Dar es Salaam roadside banda stalls and became Tanzania''s most beloved comfort meal — always paired with tangy kachumbari!'),
  ('The Pilau Spice Path', 'Authentic Swahili Pilau toasts whole cumin, cardamom, black pepper, cloves, and cinnamon in deeply caramelized onions before simmering meat and rice together.'),
  ('Coastal Coconut Magic', 'Tui la Nazi (freshly grated coconut milk) is the soul of coastal Swahili gastronomy, giving Samaki wa Kupaka and Wali wa Nazi their signature silkiness.'),
  ('Kijitonyama Flagship Kitchen', 'Our flagship Bongo Foodie kitchen in Kijitonyama, Dar es Salaam blends charcoal mkaa grilling heritage with AI-assisted recipe personalization.')
on conflict (title) do nothing;

-- 13G. Staff & Inventory Defaults
insert into public.staff_members (name, role, status, email, phone) values
  ('Juma Hamisi', 'Manager', 'active', 'juma@bongofoodie.co.tz', '+255 712 990 881'),
  ('Salma Rashid', 'Waiter', 'active', 'salma@bongofoodie.co.tz', '+255 788 123 456'),
  ('Khalfan Saidi', 'Delivery', 'active', 'khalfan@bongofoodie.co.tz', '+255 682 990 112'),
  ('Asha Bakari', 'Kitchen', 'active', 'asha@bongofoodie.co.tz', '+255 754 881 223')
on conflict (email) do nothing;

insert into public.inventory_alerts (item, status, reported_by)
select * from (values
  ('Fresh Coconut (Nazi)', 'good', 'Chef Asha'),
  ('Zanzibar Cloves & Pilau Masala', 'good', 'Chef Asha'),
  ('Sunflower Cooking Oil', 'low', 'Supply Desk')
) as v(item, status, reported_by)
where not exists (select 1 from public.inventory_alerts limit 1);

-- 13H. Tanzania Regions (All 31 Regions)
insert into public.regions (region_code, region_name) values
  (1, 'Dodoma'),
  (2, 'Arusha'),
  (3, 'Kilimanjaro'),
  (4, 'Tanga'),
  (5, 'Morogoro'),
  (6, 'Pwani'),
  (7, 'Dar es Salaam'),
  (8, 'Lindi'),
  (9, 'Mtwara'),
  (10, 'Ruvuma'),
  (11, 'Iringa'),
  (12, 'Mbeya'),
  (13, 'Singida'),
  (14, 'Tabora'),
  (15, 'Rukwa'),
  (16, 'Kigoma'),
  (17, 'Shinyanga'),
  (18, 'Kagera'),
  (19, 'Mwanza'),
  (20, 'Mara'),
  (21, 'Manyara'),
  (22, 'Njombe'),
  (23, 'Katavi'),
  (24, 'Simiyu'),
  (25, 'Geita'),
  (26, 'Songwe'),
  (27, 'Kaskazini Unguja'),
  (28, 'Kusini Unguja'),
  (29, 'Mjini Magharibi (Zanzibar)'),
  (30, 'Kaskazini Pemba'),
  (31, 'Kusini Pemba')
on conflict (region_code) do update set region_name = excluded.region_name;

-- 13I. Tanzania Districts (Full Dar es Salaam + Key Delivery Cities across all regions)
insert into public.districts (district_code, district_name, region_id) values
  -- Dar es Salaam (7)
  (701, 'Kinondoni', 7),
  (702, 'Ilala (Dar es Salaam CBD)', 7),
  (703, 'Temeke', 7),
  (704, 'Ubungo', 7),
  (705, 'Kigamboni', 7),
  -- Dodoma (1)
  (101, 'Dodoma Mjini', 1),
  (102, 'Chamwino', 1),
  -- Arusha (2)
  (201, 'Arusha Mjini', 2),
  (202, 'Arumeru', 2),
  -- Kilimanjaro (3)
  (301, 'Moshi Mjini', 3),
  (302, 'Hai', 3),
  -- Tanga (4)
  (401, 'Tanga Mjini', 4),
  (402, 'Muheza', 4),
  -- Morogoro (5)
  (501, 'Morogoro Mjini', 5),
  (502, 'Kilosa', 5),
  -- Pwani (6)
  (601, 'Kibaha Mjini', 6),
  (602, 'Bagamoyo', 6),
  -- Mjini Magharibi Zanzibar (29)
  (2901, 'Mjini (Stone Town)', 29),
  (2902, 'Magharibi A', 29),
  (2903, 'Magharibi B', 29),
  -- Mwanza (19)
  (1901, 'Nyamagana', 19),
  (1902, 'Ilemela', 19),
  -- Mbeya (12)
  (1201, 'Mbeya Mjini', 12),
  -- Iringa (11)
  (1101, 'Iringa Mjini', 11),
  -- Remaining Regional Capitals so every Region cascades cleanly
  (801, 'Lindi Mjini', 8),
  (901, 'Mtwara Mikindani', 9),
  (1001, 'Songea Mjini', 10),
  (1301, 'Singida Mjini', 13),
  (1401, 'Tabora Mjini', 14),
  (1501, 'Sumbawanga Mjini', 15),
  (1601, 'Kigoma Ujiji', 16),
  (1701, 'Shinyanga Mjini', 17),
  (1801, 'Bukoba Mjini', 18),
  (2001, 'Musoma Mjini', 20),
  (2101, 'Babati Mjini', 21),
  (2201, 'Njombe Mjini', 22),
  (2301, 'Mpanda Mjini', 23),
  (2401, 'Bariadi Mjini', 24),
  (2501, 'Geita Mjini', 25),
  (2601, 'Vwawa (Mbozi)', 26),
  (2701, 'Mkokotoni (Kaskazini A)', 27),
  (2801, 'Koani (Kati)', 28),
  (3001, 'Wete', 30),
  (3101, 'Chake Chake', 31)
on conflict (district_code) do update
set district_name = excluded.district_name, region_id = excluded.region_id;

-- 13J. Tanzania Wards (Comprehensive Dar es Salaam + Key Urban Wards)
insert into public.wards (ward_code, ward_name, district_id) values
  -- Kinondoni (701)
  (70101, 'Kijitonyama', 701),
  (70102, 'Mikocheni', 701),
  (70103, 'Msasani (Masaki / Oysterbay)', 701),
  (70104, 'Makumbusho', 701),
  (70105, 'Mwananyamala', 701),
  (70106, 'Kinondoni', 701),
  (70107, 'Kawe', 701),
  (70108, 'Mbezi Juu', 701),
  (70109, 'Kunduchi', 701),
  (70110, 'Bunju', 701),
  -- Ilala (702)
  (70201, 'Kariakoo', 702),
  (70202, 'Upanga Mashariki', 702),
  (70203, 'Upanga Magharibi', 702),
  (70204, 'Kisutu', 702),
  (70205, 'Kivukoni (Posta)', 702),
  (70206, 'Ilala', 702),
  (70207, 'Buguruni', 702),
  (70208, 'Tabata', 702),
  (70209, 'Segerea', 702),
  (70210, 'Ukonga', 702),
  -- Temeke (703)
  (70301, 'Chang''ombe', 703),
  (70302, 'Keko', 703),
  (70303, 'Kurasini', 703),
  (70304, 'Temeke', 703),
  (70305, 'Tandika', 703),
  (70306, 'Mbagala', 703),
  (70307, 'Mbagala Kuu', 703),
  -- Ubungo (704)
  (70401, 'Sinza', 704),
  (70402, 'Ubungo', 704),
  (70403, 'Mabibo', 704),
  (70404, 'Manzese', 704),
  (70405, 'Kimara', 704),
  (70406, 'Mbezi', 704),
  (70407, 'Goba', 704),
  (70408, 'Saranga', 704),
  -- Kigamboni (705)
  (70501, 'Kigamboni (Ferry)', 705),
  (70502, 'Tungi', 705),
  (70503, 'Vijibweni', 705),
  (70504, 'Mjimwema', 705),
  (70505, 'Gezaulole', 705),
  (70506, 'Kimbiji', 705),
  -- Major Regional Hubs
  (10101, 'Majengo (Dodoma CBD)', 101),
  (10102, 'Area C / Udom', 101),
  (10201, 'Buigiri', 102),
  (20101, 'Sekei', 201),
  (20102, 'Kaloleni', 201),
  (20201, 'Usa River', 202),
  (30101, 'Mawenzi', 301),
  (30201, 'Bomang''ombe', 302),
  (40101, 'Chumbageni', 401),
  (40201, 'Majengo Muheza', 402),
  (50101, 'Boma', 501),
  (50201, 'Mbumi', 502),
  (60101, 'Tumbi', 601),
  (60201, 'Dunda', 602),
  (290101, 'Shangani (Stone Town)', 2901),
  (290102, 'Mkunazini', 2901),
  (290201, 'Bububu', 2902),
  (290301, 'Mbweni', 2903),
  (190101, 'Pamba', 1901),
  (190102, 'Capri Point', 1901),
  (190201, 'Kirumba', 1902),
  (120101, 'Iyunga', 1201),
  (110101, 'Gangilonga', 1101),
  (80101, 'Rahaleo', 801),
  (90101, 'Shangani Mtwara', 901),
  (100101, 'Majengo Songea', 1001),
  (130101, 'Ipembe', 1301),
  (140101, 'Gongoni', 1401),
  (150101, 'Izia', 1501),
  (160101, 'Kigoma Mjini', 1601),
  (170101, 'Kambarage', 1701),
  (180101, 'Bilele', 1801),
  (200101, 'Mukendo', 2001),
  (210101, 'Bagara', 2101),
  (220101, 'Njombe Mjini', 2201),
  (230101, 'Kawajense', 2301),
  (240101, 'Somanda', 2401),
  (250101, 'Kalangalala', 2501),
  (260101, 'Vwawa', 2601),
  (270101, 'Nungwi', 2701),
  (280101, 'Paje / Jambiani', 2801),
  (300101, 'Bopwe', 3001),
  (310101, 'Chachani', 3101)
on conflict (ward_code) do update
set ward_name = excluded.ward_name, district_id = excluded.district_id;

-- Incremental reward authority (also shipped as migration 20261109010000).
-- Prompt 7: no campaign is activated by this migration. Deploy before the client.
create table if not exists public.reward_campaigns (
  code text primary key check (code = upper(btrim(code)) and length(code) between 1 and 40),
  active boolean not null default false,
  starts_at timestamptz not null,
  expires_at timestamptz not null check (expires_at > starts_at),
  discount numeric not null check (discount > 0 and discount < 100000000),
  minimum_subtotal numeric not null default 0 check (minimum_subtotal >= 0),
  per_user_limit integer not null default 1 check (per_user_limit > 0),
  total_limit integer not null check (total_limit > 0),
  requires_quiz boolean not null default true
);
create table if not exists public.reward_quiz_attempts (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  quiz_date date not null,
  question_id integer not null,
  answer_index integer not null check (answer_index between 0 and 3),
  is_correct boolean not null,
  primary key (profile_id, quiz_date)
);
alter table public.orders add column if not exists promo_code text not null default '';
create table if not exists public.reward_redemptions (
  order_id text primary key references public.orders(id) deferrable initially deferred,
  profile_id uuid not null references public.profiles(id),
  code text not null references public.reward_campaigns(code),
  discount numeric not null check (discount > 0),
  created_at timestamptz not null default now()
);
create index if not exists reward_redemptions_user_code on public.reward_redemptions(profile_id, code);
create index if not exists reward_redemptions_code on public.reward_redemptions(code);
alter table public.reward_campaigns enable row level security;
alter table public.reward_quiz_attempts enable row level security;
alter table public.reward_redemptions enable row level security;
-- No browser role may write rewards, even if other broad policies exist.
revoke all on public.reward_campaigns, public.reward_quiz_attempts, public.reward_redemptions from anon, authenticated;
grant select on public.reward_quiz_attempts, public.reward_redemptions to authenticated;
drop policy if exists reward_attempt_owner on public.reward_quiz_attempts;
create policy reward_attempt_owner on public.reward_quiz_attempts for select to authenticated using (profile_id = auth.uid());
drop policy if exists reward_redemption_owner on public.reward_redemptions;
create policy reward_redemption_owner on public.reward_redemptions for select to authenticated using (profile_id = auth.uid());
-- Old client-asserted results never establish an entitlement.
drop policy if exists "Users can insert their own quiz attempts" on public.quiz_attempts;
revoke insert, update, delete on public.quiz_attempts from anon, authenticated;

create or replace function public.reward_quiz_status() returns boolean
language sql security definer set search_path = '' as $$
  select exists(select 1 from public.reward_quiz_attempts where profile_id = auth.uid()
    and quiz_date = (clock_timestamp() at time zone 'Africa/Dar_es_Salaam')::date);
$$;
create or replace function public.submit_reward_quiz(p_question_id integer, p_answer_index integer) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  d date := (clock_timestamp() at time zone 'Africa/Dar_es_Salaam')::date;
  q integer;
  result boolean;
begin
  if u is null then raise exception 'reward_sign_in_required'; end if;
  q := (((d - date '2024-01-01') % 3 + 3) % 3) + 1;
  if p_question_id is distinct from q or p_answer_index is null or p_answer_index not between 0 and 3 then
    raise exception 'reward_question_changed';
  end if;
  -- IDs/options are the versioned DailyCopy v1 catalog: answers 1,0,1.
  insert into public.reward_quiz_attempts values (u, d, q, p_answer_index,
    p_answer_index = case q when 2 then 0 else 1 end)
    on conflict (profile_id, quiz_date) do nothing;
  select is_correct into result from public.reward_quiz_attempts where profile_id = u and quiz_date = d;
  return result;
end;
$$;

-- Canonical discounted basket pricing; rejects invented dishes/addons, duplicates,
-- fractional quantities and unavailable products. No client price is authoritative.
create or replace function public.reward_basket_subtotal(p_items jsonb) returns numeric
language plpgsql security definer set search_path = '' as $$
declare line jsonb; addon jsonb; unit numeric; extra numeric; qty integer; subtotal numeric := 0; seen text[];
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 100 then
    raise exception 'reward_invalid_basket';
  end if;
  for line in select value from jsonb_array_elements(p_items) loop
    if coalesce(line->>'quantity', '') !~ '^[0-9]{1,2}$' then raise exception 'reward_invalid_quantity'; end if;
    qty := (line->>'quantity')::integer;
    if qty not between 1 and 20 then raise exception 'reward_invalid_quantity'; end if;
    select price into unit from public.menu where id = (line->>'id')::uuid and is_available = true;
    if unit is null or unit < 0 or unit >= 100000000 then raise exception 'reward_item_unavailable'; end if;
    seen := array[]::text[];
    if jsonb_typeof(coalesce(line->'customizations', '[]'::jsonb)) <> 'array' then raise exception 'reward_invalid_addon'; end if;
    for addon in select value from jsonb_array_elements(coalesce(line->'customizations', '[]'::jsonb)) loop
      if addon->>'id' = any(seen) then raise exception 'reward_duplicate_addon'; end if;
      seen := array_append(seen, addon->>'id');
      select c.price into extra from public.customizations c join public.menu_customizations m on m.customization_id = c.id
        where m.menu_id = (line->>'id')::uuid and c.id = (addon->>'id')::uuid;
      if extra is null or extra < 0 or extra >= 100000000 then raise exception 'reward_invalid_addon'; end if;
      unit := unit + extra;
    end loop;
    subtotal := subtotal + unit * qty;
  end loop;
  return subtotal;
end;
$$;

create or replace function public.quote_reward(p_code text, p_items jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare c public.reward_campaigns%rowtype; u uuid := auth.uid(); subtotal numeric; fee numeric; amount numeric;
begin
  if u is null then raise exception 'reward_sign_in_required'; end if;
  -- A single campaign lock serializes all limit checks and order redemptions.
  select * into c from public.reward_campaigns where code = upper(btrim(p_code)) for update;
  if not found or not c.active or clock_timestamp() < c.starts_at or clock_timestamp() >= c.expires_at then raise exception 'reward_unavailable'; end if;
  if (select count(*) from public.reward_redemptions where code = c.code) >= c.total_limit or
     (select count(*) from public.reward_redemptions where code = c.code and profile_id = u) >= c.per_user_limit then
    raise exception 'reward_limit_reached';
  end if;
  if c.requires_quiz and not exists(select 1 from public.reward_quiz_attempts where profile_id = u
      and quiz_date = (clock_timestamp() at time zone 'Africa/Dar_es_Salaam')::date and is_correct) then
    raise exception 'reward_quiz_required';
  end if;
  subtotal := public.reward_basket_subtotal(p_items);
  if subtotal < c.minimum_subtotal then raise exception 'reward_minimum_spend'; end if;
  select delivery_fee into fee from public.settings where id = 'branch_settings';
  if fee is null or fee < 0 then raise exception 'reward_delivery_unavailable'; end if;
  amount := least(c.discount, subtotal);
  return jsonb_build_object('code', c.code, 'subtotal', subtotal, 'delivery_fee', fee,
    'discount', amount, 'total', subtotal + fee - amount);
end;
$$;

create or replace function public.enforce_order_reward() returns trigger
language plpgsql security definer set search_path = '' as $$
declare quote jsonb;
begin
  if TG_OP = 'UPDATE' then
    if (old.promo_code <> '' or new.promo_code <> '' or coalesce(new.discount_amount, 0) <> 0) and
      (new.promo_code is distinct from old.promo_code or new.profile_id is distinct from old.profile_id or
       new.items is distinct from old.items or new.total_price is distinct from old.total_price or
       new.discount_amount is distinct from old.discount_amount or new.subtotal is distinct from old.subtotal or
       new.delivery_fee is distinct from old.delivery_fee) then raise exception 'reward_order_immutable'; end if;
    return new;
  end if;
  if new.promo_code = '' then
    if coalesce(new.discount_amount, 0) <> 0 then raise exception 'reward_code_required'; end if;
    return new;
  end if;
  if auth.uid() is null or new.profile_id is distinct from auth.uid() then raise exception 'reward_owner_required'; end if;
  quote := public.quote_reward(new.promo_code, new.items::jsonb);
  if new.total_price is distinct from (quote->>'total')::numeric then raise exception 'reward_quote_changed'; end if;
  new.promo_code := quote->>'code';
  new.subtotal := (quote->>'subtotal')::numeric;
  new.delivery_fee := (quote->>'delivery_fee')::numeric;
  new.discount_amount := (quote->>'discount')::numeric;
  insert into public.reward_redemptions(order_id, profile_id, code, discount)
    values (new.id, auth.uid(), new.promo_code, new.discount_amount);
  return new;
end;
$$;
drop trigger if exists orders_reward_guard on public.orders;
create trigger orders_reward_guard before insert or update on public.orders
for each row execute function public.enforce_order_reward();

revoke all on function public.reward_quiz_status(), public.submit_reward_quiz(integer, integer),
  public.reward_basket_subtotal(jsonb), public.quote_reward(text, jsonb), public.enforce_order_reward() from public, anon, authenticated;
grant execute on function public.reward_quiz_status(), public.submit_reward_quiz(integer, integer), public.quote_reward(text, jsonb) to authenticated;

-- Achievement events (migration 20261109020000; requires reward ledger).
-- Submission milestones, not payment/delivery claims. No legacy-order backfill.
create table if not exists public.achievement_events (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null check (event_type in ('order_submitted', 'quiz_correct')),
  source_id text not null,
  recorded_at timestamptz not null default clock_timestamp(),
  primary key (profile_id, event_type, source_id)
);
alter table public.achievement_events enable row level security;
revoke all on public.achievement_events from public, anon, authenticated;

create or replace function public.record_achievement_event() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if TG_TABLE_NAME = 'orders' then
    if auth.uid() is not null and new.profile_id = auth.uid() then
      insert into public.achievement_events(profile_id, event_type, source_id)
      values (new.profile_id, 'order_submitted', new.id) on conflict do nothing;
    end if;
  elsif TG_TABLE_NAME = 'reward_quiz_attempts' and new.is_correct then
    insert into public.achievement_events(profile_id, event_type, source_id)
    values (new.profile_id, 'quiz_correct', new.quiz_date::text) on conflict do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists orders_achievement_event on public.orders;
create trigger orders_achievement_event after insert on public.orders
for each row execute function public.record_achievement_event();
drop trigger if exists quiz_achievement_event on public.reward_quiz_attempts;
create trigger quiz_achievement_event after insert on public.reward_quiz_attempts
for each row execute function public.record_achievement_event();
-- Only the server-owned P7 quiz ledger is eligible for historical recognition.
insert into public.achievement_events(profile_id, event_type, source_id)
select profile_id, 'quiz_correct', quiz_date::text from public.reward_quiz_attempts
where is_correct on conflict do nothing;

create or replace function public.achievement_progress() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'achievement_sign_in_required'; end if;
  select jsonb_build_object(
    'orders_submitted', count(*) filter (where event_type = 'order_submitted'),
    'correct_quizzes', count(*) filter (where event_type = 'quiz_correct'))
  into result from public.achievement_events where profile_id = auth.uid();
  return result;
end;
$$;
revoke all on function public.record_achievement_event(), public.achievement_progress() from public, anon, authenticated;
grant execute on function public.achievement_progress() to authenticated;
