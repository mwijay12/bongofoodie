-- Isolated database fixture only. NEVER run fixture/assertions on production.
create function pg_temp.expect_error(command text, expected text) returns void language plpgsql as $$
begin
  begin execute command; exception when others then
    if position(expected in sqlerrm) > 0 then return; end if;
    raise exception 'Unexpected error: % (wanted %)', sqlerrm, expected;
  end;
  raise exception 'Command unexpectedly succeeded: %', command;
end $$;
insert into profiles values ('11111111-1111-1111-1111-111111111111'), ('22222222-2222-2222-2222-222222222222');
insert into menu values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 10000, true);
insert into settings values ('branch_settings', 2000);
insert into reward_campaigns values ('TEST', true, now()-interval '1 day', now()+interval '1 day', 2000, 5000, 1, 2, false);
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select quote_reward(' test ', '[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1,"price":1}]');
select pg_temp.expect_error($q$select quote_reward('missing', '[]')$q$, 'reward_unavailable');
select pg_temp.expect_error($q$select quote_reward('TEST', '[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":0}]')$q$, 'reward_invalid_quantity');
select pg_temp.expect_error($q$select quote_reward('TEST', '[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1,"customizations":[{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","price":0}]}]')$q$, 'reward_invalid_addon');
select pg_temp.expect_error($q$insert into orders(id,profile_id,items,total_price,promo_code) values ('tampered','11111111-1111-1111-1111-111111111111','[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,'TEST')$q$, 'reward_quote_changed');
select pg_temp.expect_error($q$insert into orders(id,profile_id,items,total_price,promo_code) values ('wrong-owner','22222222-2222-2222-2222-222222222222','[]',1,'TEST')$q$, 'reward_owner_required');
select pg_temp.expect_error($q$insert into orders(id,items,total_price,discount_amount) values ('no-code','[]',1,2000)$q$, 'reward_code_required');
-- No consumption at quote or failed insert.
do $$begin if exists(select 1 from reward_redemptions) then raise exception 'quote consumed'; end if; end$$;
-- Check transaction rollback restores entitlement too.
-- SPLIT
begin;
insert into orders(id,profile_id,items,total_price,promo_code) values ('rollback','11111111-1111-1111-1111-111111111111','[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',10000,'TEST');
rollback;
-- SPLIT
insert into orders(id,profile_id,items,total_price,promo_code) values ('success','11111111-1111-1111-1111-111111111111','[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',10000,'TEST');
do $$begin
 if (select count(*) from reward_redemptions) <> 1 then raise exception 'ledger mismatch'; end if;
 if (select discount_amount from orders where id='success') <> 2000 then raise exception 'discount mismatch'; end if;
end$$;
select pg_temp.expect_error($q$select quote_reward('TEST','[]')$q$, 'reward_limit_reached');
select pg_temp.expect_error($q$update orders set total_price=1 where id='success'$q$, 'reward_order_immutable');
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
update reward_campaigns set expires_at = now()-interval '1 second', starts_at=now()-interval '2 days';
select pg_temp.expect_error($q$select quote_reward('TEST','[]')$q$, 'reward_unavailable');
update reward_campaigns set expires_at = now()+interval '1 day', requires_quiz=true;
select pg_temp.expect_error($q$select quote_reward('TEST','[]')$q$, 'reward_quiz_required');
-- One authoritative attempt/day. Second answer cannot turn a loss into a win.
select submit_reward_quiz(((((now() at time zone 'Africa/Dar_es_Salaam')::date-date '2024-01-01')%3+3)%3)+1, 3);
select submit_reward_quiz(((((now() at time zone 'Africa/Dar_es_Salaam')::date-date '2024-01-01')%3+3)%3)+1, 1);
do $$begin if exists(select 1 from reward_quiz_attempts where is_correct) then raise exception 'replay granted win'; end if; end$$;
update reward_campaigns set requires_quiz=false, minimum_subtotal=20000;
select pg_temp.expect_error($q$select quote_reward('TEST','[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]')$q$, 'reward_minimum_spend');
update reward_campaigns set minimum_subtotal=0, total_limit=1;
select pg_temp.expect_error($q$select quote_reward('TEST','[]')$q$, 'reward_limit_reached');
set role authenticated;
select pg_temp.expect_error($q$insert into reward_quiz_attempts values ('22222222-2222-2222-2222-222222222222',current_date,1,1,true)$q$, 'permission denied');
select pg_temp.expect_error($q$insert into reward_redemptions values ('fake','22222222-2222-2222-2222-222222222222','TEST',2000,now())$q$, 'permission denied');
select pg_temp.expect_error($q$select * from reward_campaigns$q$, 'permission denied');
do $$begin
 if exists(select 1 from public.reward_redemptions) then raise exception 'RLS exposed another user redemption'; end if;
end$$;
reset role;
select set_config('request.jwt.claim.sub', '', false);
select pg_temp.expect_error($q$select quote_reward('TEST','[]')$q$, 'reward_sign_in_required');
