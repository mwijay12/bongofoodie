-- Prompt 6: remove emoji code points from legacy seed rows.
-- Idempotent: a second run matches no rows; no columns or RLS policies change.
-- Text columns touched (from the STEP 0 audit):
--   public.settings.logo
--   public.promotions.discount_badge
--   public.daily_discoveries.title
-- Promo titles/subtitles, discovery descriptions and menu descriptions were
-- already clean, so they are deliberately not updated here.
--
-- The bracket expression is built from numeric Unicode code points so this
-- file contains no literal emoji characters. Ranges covered:
--   U+1F000..U+1FAFF  pictographs, emoticons, flags, skin tones
--   U+2600..U+27BF    miscellaneous symbols and dingbats
--   U+2B00..U+2BFF    stars and emoji-style arrows
--   U+FE0F            variation selector-16
--   U+200D            zero width joiner (ZWJ sequences)
--   U+20E3            combining enclosing keycap
do $$
declare
  emoji_class text;
  double_spaces constant text := ' {2,}';
begin
  select '[' || string_agg(chr(cp), '' order by cp) || ']'
  into emoji_class
  from (
    select generate_series(127744, 129535) as cp   -- U+1F000..U+1FAFF
    union all
    select generate_series(9728, 10175)            -- U+2600..U+27BF
    union all
    select generate_series(11008, 11263)           -- U+2B00..U+2BFF
    union all
    select unnest(array[65039, 8205, 8419])        -- VS16, ZWJ, keycap
  ) as code_points;

  update public.settings
     set logo = btrim(
       regexp_replace(
         regexp_replace(logo, emoji_class, '', 'g'), double_spaces, ' ', 'g'
       )
     )
   where logo is not null and logo ~ emoji_class;

  update public.promotions
     set discount_badge = btrim(
       regexp_replace(
         regexp_replace(discount_badge, emoji_class, '', 'g'),
         double_spaces, ' ', 'g'
       )
     )
   where discount_badge is not null and discount_badge ~ emoji_class;

  update public.daily_discoveries
     set title = btrim(
       regexp_replace(
         regexp_replace(title, emoji_class, '', 'g'), double_spaces, ' ', 'g'
       )
     )
   where title is not null and title ~ emoji_class;
end $$;
