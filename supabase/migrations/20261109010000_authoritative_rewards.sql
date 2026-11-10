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
