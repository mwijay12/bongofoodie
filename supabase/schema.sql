-- 1. Create Profiles Table (Linked to Supabase Auth)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  updated_at timestamp with time zone,
  name text,
  email text,
  avatar_url text
);

-- Enable RLS on Profiles
alter table public.profiles enable row level security;

drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
create policy "Public profiles are viewable by everyone." on public.profiles
  for select using (true);

drop policy if exists "Users can insert their own profile." on public.profiles;
create policy "Users can insert their own profile." on public.profiles
  for insert with check ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile." on public.profiles;
create policy "Users can update their own profile." on public.profiles
  for update using ((select auth.uid()) = id);

-- Trigger to automatically create a profile for new users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Bongo Foodie User'),
    new.email,
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Recreate trigger cleanly
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. Create Categories Table
create table if not exists public.categories (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  description text,
  created_at timestamp with time zone default now()
);

alter table public.categories enable row level security;
drop policy if exists "Categories are viewable by everyone" on public.categories;
create policy "Categories are viewable by everyone" on public.categories for select using (true);

-- 3. Create Customizations Table
create table if not exists public.customizations (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  price numeric not null,
  type text not null, -- 'topping', 'side', 'drink', etc.
  created_at timestamp with time zone default now()
);

alter table public.customizations enable row level security;
drop policy if exists "Customizations are viewable by everyone" on public.customizations;
create policy "Customizations are viewable by everyone" on public.customizations for select using (true);

-- 4. Create Menu Items Table
create table if not exists public.menu (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  description text not null,
  image_url text not null,
  price numeric not null,
  rating numeric default 0,
  calories integer,
  protein integer,
  category_id uuid references public.categories(id) on delete set null,
  created_at timestamp with time zone default now()
);

alter table public.menu enable row level security;
drop policy if exists "Menu items are viewable by everyone" on public.menu;
create policy "Menu items are viewable by everyone" on public.menu for select using (true);
drop policy if exists "Anyone can update menu items" on public.menu;
create policy "Anyone can update menu items" on public.menu for update using (true);

-- 5. Create Menu-Customizations Association Table (Many-to-Many)
create table if not exists public.menu_customizations (
  id uuid default gen_random_uuid() primary key,
  menu_id uuid references public.menu(id) on delete cascade not null,
  customization_id uuid references public.customizations(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (menu_id, customization_id)
);

alter table public.menu_customizations enable row level security;
drop policy if exists "Menu customizations are viewable by everyone" on public.menu_customizations;
create policy "Menu customizations are viewable by everyone" on public.menu_customizations for select using (true);

-- 6. Create Orders Table
create table if not exists public.orders (
  id text primary key,
  profile_id uuid references public.profiles(id) on delete set null,
  table_number text default 'Takeaway / Delivery',
  items text not null, -- JSON string of items
  status text default 'pending',
  total_price numeric not null,
  delivery_location text default 'Dar es Salaam',
  customer_name text default 'Guest Customer',
  customer_email text default 'no-phone@email.com',
  created_at timestamp with time zone default now()
);

-- Enable RLS on Orders
alter table public.orders enable row level security;

-- Create Policies for Orders
drop policy if exists "Everyone can insert orders." on public.orders;
create policy "Everyone can insert orders." on public.orders for insert with check (true);
drop policy if exists "Users can view their own orders or Admin can view all." on public.orders;
create policy "Users can view their own orders or Admin can view all." on public.orders for select using (
  (select auth.uid()) = profile_id OR 
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);
drop policy if exists "Users can update their own orders or Admin can update all." on public.orders;
create policy "Users can update their own orders or Admin can update all." on public.orders for update using (
  (select auth.uid()) = profile_id OR 
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);

-- 7. Create Settings Table
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
  logo text default '🔥',
  updated_at timestamp with time zone default now()
);

-- Enable RLS on Settings
alter table public.settings enable row level security;
drop policy if exists "Settings are viewable by everyone" on public.settings;
create policy "Settings are viewable by everyone" on public.settings for select using (true);
drop policy if exists "Only admin can update settings" on public.settings;
create policy "Only admin can update settings" on public.settings for update using (
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);
drop policy if exists "Only admin can insert settings" on public.settings;
create policy "Only admin can insert settings" on public.settings for insert with check (
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);

-- Insert default row if not exists
insert into public.settings (id, restaurant_name, branch_address, phone, mpesa_till, tigo_till, airtel_till, halo_till, nmb_account, crdb_account, logo)
values ('branch_settings', 'Bongo Foodie', 'Kijitonyama Branch, Dar es Salaam', '+255 712 345 678', '556677', '223344', '889900', '112233', '9900112233', '8877665544', '🔥')
on conflict (id) do nothing;

-- 8. Create Favorites Table
create table if not exists public.favorites (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  menu_id uuid references public.menu(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique (profile_id, menu_id)
);

-- Enable RLS on Favorites
alter table public.favorites enable row level security;
drop policy if exists "Users can view their own favorites" on public.favorites;
create policy "Users can view their own favorites" on public.favorites for select using (
  auth.uid() = profile_id
);
drop policy if exists "Users can insert their own favorites" on public.favorites;
create policy "Users can insert their own favorites" on public.favorites for insert with check (
  auth.uid() = profile_id
);
drop policy if exists "Users can delete their own favorites" on public.favorites;
create policy "Users can delete their own favorites" on public.favorites for delete using (
  auth.uid() = profile_id
);

-- 9. Create Daily Discoveries Table (Admin-managed culinary facts)
create table if not exists public.daily_discoveries (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.daily_discoveries enable row level security;
drop policy if exists "Daily discoveries are viewable by everyone" on public.daily_discoveries;
create policy "Daily discoveries are viewable by everyone" on public.daily_discoveries for select using (true);
drop policy if exists "Only admin can insert daily discoveries" on public.daily_discoveries;
create policy "Only admin can insert daily discoveries" on public.daily_discoveries for insert with check (
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);
drop policy if exists "Only admin can update daily discoveries" on public.daily_discoveries;
create policy "Only admin can update daily discoveries" on public.daily_discoveries for update using (
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);
drop policy if exists "Only admin can delete daily discoveries" on public.daily_discoveries;
create policy "Only admin can delete daily discoveries" on public.daily_discoveries for delete using (
  (select auth.jwt() ->> 'email') = 'defoodordering@gmail.com'
);

-- Insert default daily discoveries
insert into public.daily_discoveries (title, description) values
('Zanzibar Spice Capital 🌴', 'Zanzibar (Unguja) is nicknamed the ''Spice Island'' because it remains one of the world''s top exporters of Cloves (Karafuu) and Nutmeg.'),
('Bongo Foodie Sourcing 🧑‍🌾', 'We source 100% of our organic vegetables, fresh meat, and rice from local Tanzanian family farms, supporting sustainable community growth!'),
('Eco-Friendly Delivery 📦', 'To minimize plastic waste, all Bongo Foodie deliveries use biodegradable boxes inspired by traditional East African banana leaves.'),
('National Comfort Food 🍟', 'Chipsi Mayai (French Fries Omelette) started as a cheap roadside breakfast in Dar es Salaam and has evolved into Tanzania''s most famous street food!'),
('Our Kijitonyama Branch 📍', 'Bongo Foodie opened its first physical branch in Kijitonyama, Dar es Salaam, aiming to bring high-end premium dining experiences to local foodies.'),
('The Pilau Path 🍛', 'Swahili Pilau is distinct because it roasts dry spices (cumin, cardamom, cloves, cinnamon) in caramelized onions before adding meat and rice.'),
('Coastal Coconut Magic 🥥', 'Tui la Nazi (Fresh Coconut Milk) is the soul of coastal cooking, used to simmer Samaki wa Kupaka (Coastal Fish Curry) or Maharage ya Nazi.')
on conflict do nothing;

-- 10. Create Quiz Attempts Table (tracks who attempted the daily quiz)
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
create policy "Users can view their own quiz attempts" on public.quiz_attempts for select using (
  auth.uid() = profile_id
);
drop policy if exists "Users can insert their own quiz attempts" on public.quiz_attempts;
create policy "Users can insert their own quiz attempts" on public.quiz_attempts for insert with check (
  auth.uid() = profile_id
);

-- 11. Create User Settings Table (notification preferences, etc.)
create table if not exists public.user_settings (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null unique,
  push_notifications boolean default true,
  email_notifications boolean default true,
  sms_notifications boolean default false,
  order_updates boolean default true,
  promotional_offers boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table public.user_settings enable row level security;
drop policy if exists "Users can view their own settings" on public.user_settings;
create policy "Users can view their own settings" on public.user_settings for select using (
  auth.uid() = profile_id
);
drop policy if exists "Users can insert their own settings" on public.user_settings;
create policy "Users can insert their own settings" on public.user_settings for insert with check (
  auth.uid() = profile_id
);
drop policy if exists "Users can update their own settings" on public.user_settings;
create policy "Users can update their own settings" on public.user_settings for update using (
  auth.uid() = profile_id
);