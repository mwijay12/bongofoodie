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
