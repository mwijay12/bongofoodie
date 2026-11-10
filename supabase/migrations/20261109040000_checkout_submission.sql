-- Undeployed, disabled-by-default submission foundation. Requires prior migrations.
create table if not exists public.checkout_runtime (
  id boolean primary key default true check (id),
  submission_enabled boolean not null default false
);
insert into public.checkout_runtime(id) values(true) on conflict do nothing;
alter table public.checkout_runtime enable row level security;
revoke all on public.checkout_runtime from public, anon, authenticated;

create table if not exists public.checkout_requests (
  owner_id uuid not null references public.profiles(id) on delete cascade,
  request_key uuid not null,
  -- jsonb equality is the authoritative fingerprint; never rely on a short hash.
  request_body jsonb not null,
  order_id text unique references public.orders(id) deferrable initially deferred,
  response jsonb,
  created_at timestamptz not null default now(),
  primary key(owner_id, request_key)
);
alter table public.checkout_requests enable row level security;
revoke all on public.checkout_requests from public, anon, authenticated;

create or replace function public.submit_checkout(p_key uuid, p_request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare u uuid := auth.uid(); stored public.checkout_requests%rowtype;
  quote jsonb; snapshots jsonb := '[]'; line jsonb; addon jsonb; extras jsonb;
  item public.menu%rowtype; extra public.customizations%rowtype;
  name text; phone text; address text; method text; code text; notes text; oid text;
begin
  if u is null then raise exception 'checkout_session_required'; end if;
  if p_key is null or p_request is null or jsonb_typeof(p_request) <> 'object' or
    octet_length(p_request::text) > 65536 then
    raise exception 'checkout_invalid_request';
  end if;
  -- Unique insert waits for a concurrent same-key transaction to commit/rollback.
  insert into public.checkout_requests(owner_id,request_key,request_body)
    values(u,p_key,p_request) on conflict do nothing;
  select * into stored from public.checkout_requests where owner_id=u and request_key=p_key for update;
  if stored.request_body is distinct from p_request then raise exception 'checkout_request_changed'; end if;
  if stored.response is not null then return stored.response; end if;
  lock table public.checkout_runtime in share mode;
  if not exists(select 1 from public.checkout_runtime where id and submission_enabled) then
    raise exception 'checkout_submission_disabled';
  end if;
  if p_request->>'version' is distinct from '1' or
    exists(select 1 from jsonb_object_keys(p_request) k where k not in
      ('version','items','region','district','ward','promo_code','name','phone','address','payment_method','notes','reviewed_quote')) then
    raise exception 'checkout_invalid_request';
  end if;
  if exists(select 1 from unnest(array['name','phone','address','payment_method']) k
    where jsonb_typeof(p_request->k) is distinct from 'string') or
    (p_request ? 'notes' and jsonb_typeof(p_request->'notes') is distinct from 'string') or
    (p_request ? 'promo_code' and jsonb_typeof(p_request->'promo_code') is distinct from 'string') then
    raise exception 'checkout_invalid_recipient';
  end if;
  name := btrim(p_request->>'name'); phone := p_request->>'phone';
  address := btrim(p_request->>'address'); method := p_request->>'payment_method';
  code := coalesce(p_request->>'promo_code',''); notes := coalesce(p_request->>'notes','');
  if name is null or length(name) not between 2 and 100 or name ~ '[[:cntrl:]]' or
    phone is null or phone !~ '^\+255[67][0-9]{8}$' or
    address is null or length(address) not between 10 and 500 or
    method is null or method not in ('cash','lipanamba') or length(notes)>1000 then
    raise exception 'checkout_invalid_recipient';
  end if;
  -- Transaction-scoped catalog/config SHARE locks prevent edits between repricing
  -- and snapshots/insert. Concurrent checkouts share them; catalog edits wait.
  lock table public.menu, public.customizations, public.menu_customizations,
    public.settings, public.checkout_service_wards, public.regions, public.districts,
    public.wards in share mode;
  quote := public.quote_checkout(p_request->'items',(p_request->>'region')::integer,
    (p_request->>'district')::integer,(p_request->>'ward')::integer,code);
  if p_request->'reviewed_quote' is distinct from quote then raise exception 'checkout_review_changed'; end if;
  for line in select value from jsonb_array_elements(p_request->'items') loop
    select * into strict item from public.menu where id=(line->>'id')::uuid;
    extras := '[]';
    for addon in select value from jsonb_array_elements(coalesce(line->'customizations','[]')) loop
      select * into strict extra from public.customizations where id=(addon->>'id')::uuid;
      extras := extras || jsonb_build_array(jsonb_build_object('id',extra.id,'name',extra.name,'price',extra.price));
    end loop;
    snapshots := snapshots || jsonb_build_array(jsonb_build_object('id',item.id,
      'name',item.name,'price',item.price,'quantity',(line->>'quantity')::integer,
      'customizations',extras));
  end loop;
  -- Request keys are scoped to the owner; order IDs are independently random.
  oid := 'BF-' || gen_random_uuid()::text;
  insert into public.orders(id,profile_id,items,status,subtotal,delivery_fee,
    discount_amount,total_price,promo_code,customer_name,customer_phone,
    delivery_location,payment_method,notes)
    values(oid,u,snapshots::text,'pending',(quote->>'subtotal')::numeric,
      (quote->>'delivery_fee')::numeric,(quote->>'discount')::numeric,
      (quote->>'total')::numeric,quote->>'promo_code',name,phone,address,method,notes);
  -- Return a saved immutable submission response, not a paid/delivered assertion.
  quote := jsonb_build_object('version',1,'order_id',oid,'status','pending',
    'payment_state','unconfirmed','quote',quote,'items',snapshots);
  update public.checkout_requests set order_id=oid,response=quote
    where owner_id=u and request_key=p_key;
  return quote;
end $$;

create or replace function public.lookup_checkout(p_key uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb; begin
  if auth.uid() is null then raise exception 'checkout_session_required'; end if;
  select response into result from public.checkout_requests
    where owner_id=auth.uid() and request_key=p_key;
  -- NULL means no committed owned result visible NOW. It does not prove a write
  -- is absent/inactive: another transaction/network request may still be running.
  return result;
end $$;
revoke all on function public.submit_checkout(uuid,jsonb),public.lookup_checkout(uuid) from public,anon,authenticated;
grant execute on function public.submit_checkout(uuid,jsonb),public.lookup_checkout(uuid) to authenticated;
