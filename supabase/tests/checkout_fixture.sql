-- Isolated fixture only; run after reward/achievement tests, NEVER on production.
create table public.regions(region_code integer primary key);
create table public.districts(district_code integer primary key, region_id integer references public.regions);
create table public.wards(ward_code integer primary key, district_id integer references public.districts);
-- Model legacy Supabase privileges to prove migration actually removes them.
grant usage on schema public to anon, authenticated;
grant all on public.orders to anon, authenticated;
alter table public.orders enable row level security;
create policy "Everyone can insert orders." on public.orders for insert with check(true);
create policy "Users or Staff can update orders" on public.orders for update using(true);
