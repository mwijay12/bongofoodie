-- Undeployed Prompt11 foundation. Applying closes legacy direct client writes;
-- mobile checkout remains disabled until submission/ownership/replay are complete.
-- Keep operators/service_role migration access; never grant these writes back to
-- authenticated just to restore an old client. No service coverage is seeded.
revoke insert, update, delete, truncate, references, trigger on public.orders from public, anon, authenticated;
drop policy if exists "Everyone can insert orders." on public.orders;
drop policy if exists "Users can update their own orders or Admin can update all." on public.orders;
drop policy if exists "Users or Staff can update orders" on public.orders;

create table if not exists public.checkout_service_wards (
  ward_code integer primary key references public.wards(ward_code),
  enabled boolean not null default false,
  -- Human-reviewed operational source, not an assertion of verified GPS/address.
  evidence text not null check (length(btrim(evidence)) between 10 and 2000),
  reviewed_at timestamptz not null default now()
);
alter table public.checkout_service_wards enable row level security;
revoke all on public.checkout_service_wards from public, anon, authenticated;

-- Quote only: no order creation, reservation, campaign consumption, payment or
-- promise of kitchen acceptance. Caller must own an authenticated server session;
-- a future reviewed anonymous-auth contract may satisfy this without an account.
create or replace function public.quote_checkout(
  p_items jsonb, p_region integer, p_district integer, p_ward integer,
  p_code text default ''
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare subtotal numeric; fee numeric; discount numeric := 0; reward jsonb;
begin
  if auth.uid() is null then raise exception 'checkout_session_required'; end if;
  if not exists(select 1 from public.wards w
    join public.districts d on d.district_code = w.district_id
    join public.regions r on r.region_code = d.region_id
    join public.checkout_service_wards s on s.ward_code = w.ward_code
    where w.ward_code = p_ward and d.district_code = p_district
      and r.region_code = p_region and s.enabled) then
    raise exception 'checkout_area_unavailable';
  end if;
  -- Reuse strict catalog pricing for ALL baskets, including non-discounted ones.
  subtotal := public.reward_basket_subtotal(p_items);
  select delivery_fee into fee from public.settings where id = 'branch_settings';
  if fee is null or fee < 0 or fee >= 100000000 or fee::text in ('NaN','Infinity','-Infinity') then
    raise exception 'checkout_delivery_unavailable';
  end if;
  if subtotal is null or subtotal < 0 or subtotal::text in ('NaN','Infinity','-Infinity') then
    raise exception 'checkout_invalid_total';
  end if;
  if p_code is null or length(p_code) > 100 then raise exception 'checkout_invalid_code'; end if;
  if btrim(p_code) <> '' then
    reward := public.quote_reward(p_code, p_items);
    -- Same function call snapshot; never accept client totals/discount fields.
    discount := (reward->>'discount')::numeric;
    if (reward->>'subtotal')::numeric is distinct from subtotal or
       (reward->>'delivery_fee')::numeric is distinct from fee or
       discount is null or discount < 0 or discount > subtotal or
       discount::text in ('NaN','Infinity','-Infinity') then
      raise exception 'checkout_quote_changed';
    end if;
  end if;
  return jsonb_build_object('version', 1, 'currency', 'TZS', 'subtotal', subtotal,
    'delivery_fee', fee, 'discount', discount, 'total', subtotal + fee - discount,
    'promo_code', coalesce(reward->>'code',''), 'region',p_region,
    'district',p_district,'ward',p_ward);
end $$;
revoke all on function public.quote_checkout(jsonb,integer,integer,integer,text) from public, anon;
grant execute on function public.quote_checkout(jsonb,integer,integer,integer,text) to authenticated;
