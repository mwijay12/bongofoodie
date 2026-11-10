-- Isolated DB only. UUIDs/area are fictional fixtures.
create function pg_temp.expect_error(command text, expected text) returns void language plpgsql as $$
begin
 begin execute command; exception when others then
  if position(expected in sqlerrm)>0 then return; end if;
  raise exception 'Unexpected error: % (wanted %)',sqlerrm,expected;
 end;
 raise exception 'Command unexpectedly succeeded: %',command;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
update checkout_service_wards set enabled=true where ward_code=100;
-- A temp request helps test identical canonical JSON replay without client prices.
create temporary table request_fixture(body jsonb);
insert into request_fixture select jsonb_build_object('version',1,'items',
 '[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1,"name":"FORGED","price":1}]'::jsonb,
 'region',1,'district',10,'ward',100,'name','Asha Juma','phone','+255712345678',
 'address','TEST address only, House 14','payment_method','cash','notes','',
 'reviewed_quote',quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100));
select pg_temp.expect_error($q$select submit_checkout('10000000-0000-4000-8000-000000000001',(select body from request_fixture))$q$,'checkout_submission_disabled');
do $$begin if exists(select 1 from checkout_requests) then raise exception 'disabled left request'; end if; end$$;
update checkout_runtime set submission_enabled=true;
select pg_temp.expect_error($q$select submit_checkout('10000000-0000-4000-8000-000000000001',(select body || '{"phone":"dummy"}'::jsonb from request_fixture))$q$,'checkout_invalid_recipient');
select pg_temp.expect_error($q$select submit_checkout('10000000-0000-4000-8000-000000000001',(select jsonb_set(body,'{reviewed_quote,total}','1') from request_fixture))$q$,'checkout_review_changed');
begin;
select submit_checkout('10000000-0000-4000-8000-000000000002',(select body from request_fixture));
rollback;
do $$begin if exists(select 1 from checkout_requests) then raise exception 'rollback left ledger'; end if; end$$;
select submit_checkout('10000000-0000-4000-8000-000000000001',(select body from request_fixture));
do $$declare a jsonb; b jsonb; begin
 a:=lookup_checkout('10000000-0000-4000-8000-000000000001');
 b:=submit_checkout('10000000-0000-4000-8000-000000000001',(select body from request_fixture));
 if a is distinct from b or a->>'status'<>'pending' or a->>'payment_state'<>'unconfirmed' then raise exception 'replay/status mismatch'; end if;
 if a->'items'->0->>'name'<>'Catalog Pilau' or a->'items'->0->>'price'='1' then raise exception 'client snapshot trusted'; end if;
 if (select count(*) from checkout_requests)<>1 then raise exception 'duplicate request'; end if;
end$$;
select pg_temp.expect_error($q$select submit_checkout('10000000-0000-4000-8000-000000000001',(select body || '{"notes":"changed"}'::jsonb from request_fixture))$q$,'checkout_request_changed');
-- Replay survives later price/coverage/gate changes, without another insert.
update checkout_runtime set submission_enabled=false;
update checkout_service_wards set enabled=false;
update menu set price=12000;
select submit_checkout('10000000-0000-4000-8000-000000000001',(select body from request_fixture));
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
do $$begin if lookup_checkout('10000000-0000-4000-8000-000000000001') is not null then raise exception 'cross-owner leak'; end if; end$$;
set role authenticated;
select pg_temp.expect_error($q$select * from checkout_requests$q$,'permission denied');
select pg_temp.expect_error($q$update checkout_runtime set submission_enabled=true$q$,'permission denied');
reset role;
set role anon;
select pg_temp.expect_error($q$select lookup_checkout('10000000-0000-4000-8000-000000000001')$q$,'permission denied');
reset role;
select set_config('request.jwt.claim.sub','',false);
select pg_temp.expect_error($q$select lookup_checkout('10000000-0000-4000-8000-000000000001')$q$,'checkout_session_required');
