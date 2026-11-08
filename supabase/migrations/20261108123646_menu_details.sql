-- Add optional premium dish-detail fields to public.menu.
-- Uses lowercase snake_case identifiers, appropriate smallint/text[]/text types,
-- and add column if not exists so re-running the migration is a no-op.
-- The inline check is part of the conditional column addition; no policy changes.

alter table public.menu add column if not exists spice_level smallint check (spice_level between 0 and 5), add column if not exists ingredients text[] not null default '{}', add column if not exists allergens text[] not null default '{}', add column if not exists fun_fact_en text, add column if not exists fun_fact_sw text;
