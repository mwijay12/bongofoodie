-- Isolated fixture delta only, NEVER production. Reflect full-schema columns used.
alter table public.menu add column name text not null default 'Catalog Pilau';
alter table public.customizations add column name text not null default 'Catalog extra';
alter table public.orders add column status text not null default 'pending';
alter table public.orders add column customer_name text;
alter table public.orders add column customer_phone text;
alter table public.orders add column delivery_location text;
alter table public.orders add column payment_method text;
alter table public.orders add column notes text;
