-- Isolated fixture only, run after reward assertions and achievement migration.
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
do $$begin
 if (achievement_progress()->>'orders_submitted')::int <> 0 then raise exception 'legacy orders granted awards'; end if;
end$$;
insert into orders(id,profile_id,items,total_price) values
 ('achievement-one','11111111-1111-1111-1111-111111111111','[]',0),
 ('achievement-two','11111111-1111-1111-1111-111111111111','[]',0),
 ('achievement-three','11111111-1111-1111-1111-111111111111','[]',0);
-- Wrong-owner legacy insert policy cannot grant a badge to another user.
insert into orders(id,profile_id,items,total_price) values ('achievement-forged','22222222-2222-2222-2222-222222222222','[]',0);
do $$begin
 if (achievement_progress()->>'orders_submitted')::int <> 3 then raise exception 'submission count mismatch'; end if;
end$$;
update orders set total_price=1 where id='achievement-one';
do $$begin
 if (achievement_progress()->>'orders_submitted')::int <> 3 then raise exception 'update duplicated event'; end if;
end$$;
-- Failed transactions cannot leave achievement events.
begin;
insert into orders(id,profile_id,items,total_price) values ('achievement-rollback','11111111-1111-1111-1111-111111111111','[]',0);
rollback;
-- SPLIT
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
do $$begin
 if (achievement_progress()->>'orders_submitted')::int <> 3 then raise exception 'rollback left event'; end if;
end$$;
select submit_reward_quiz(((((now() at time zone 'Africa/Dar_es_Salaam')::date-date '2024-01-01')%3+3)%3)+1,
 case (((((now() at time zone 'Africa/Dar_es_Salaam')::date-date '2024-01-01')%3+3)%3)+1) when 2 then 0 else 1 end);
select submit_reward_quiz(((((now() at time zone 'Africa/Dar_es_Salaam')::date-date '2024-01-01')%3+3)%3)+1,3);
do $$begin
 if (achievement_progress()->>'correct_quizzes')::int <> 1 then raise exception 'quiz award missing or duplicated'; end if;
end$$;
set role authenticated;
select pg_temp.expect_error($q$insert into achievement_events values ('11111111-1111-1111-1111-111111111111','quiz_correct','fake',now())$q$, 'permission denied');
select pg_temp.expect_error($q$select * from achievement_events$q$, 'permission denied');
select pg_temp.expect_error($q$delete from achievement_events$q$, 'permission denied');
reset role;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
do $$begin
 if (achievement_progress()->>'orders_submitted')::int <> 0 or (achievement_progress()->>'correct_quizzes')::int <> 0 then
  raise exception 'other account received awards';
 end if;
end$$;
select set_config('request.jwt.claim.sub', '', false);
select pg_temp.expect_error($q$select achievement_progress()$q$, 'achievement_sign_in_required');
