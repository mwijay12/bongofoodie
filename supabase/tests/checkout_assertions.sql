-- Isolated database ONLY. No real geographic codes/coverage are declared here.
create function pg_temp.expect_error(command text, expected text) returns void language plpgsql as $$
begin
  begin execute command; exception when others then
    if position(expected in sqlerrm) > 0 then return; end if;
    raise exception 'Unexpected error: % (wanted %)', sqlerrm, expected;
  end;
  raise exception 'Command unexpectedly succeeded: %', command;
end $$;
insert into regions values (1),(2);
insert into districts values (10,1),(20,2);
insert into wards values (100,10),(101,10),(200,20);
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100)$q$,'checkout_area_unavailable');
insert into checkout_service_wards values (100,false,'TEST fixture only, not real coverage',now());
select pg_temp.expect_error($q$select quote_checkout('[]',1,10,100)$q$,'checkout_area_unavailable');
update checkout_service_wards set enabled=true where ward_code=100;
select pg_temp.expect_error($q$select quote_checkout('[]',2,10,100)$q$,'checkout_area_unavailable');
select pg_temp.expect_error($q$select quote_checkout('[]',1,20,100)$q$,'checkout_area_unavailable');
select pg_temp.expect_error($q$select quote_checkout('[]',1,10,101)$q$,'checkout_area_unavailable');
update settings set delivery_fee=2000 where id='branch_settings';
update menu set price=10000,is_available=true where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
insert into customizations values ('cccccccc-cccc-cccc-cccc-cccccccccccc',1000);
insert into menu_customizations values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','cccccccc-cccc-cccc-cccc-cccccccccccc');
do $$declare q jsonb; begin
 q := quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":2,"price":1,"customizations":[{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc","price":0}]}]',1,10,100);
 if q->>'total' <> '24000' or q->>'discount' <> '0' then raise exception 'client price trusted: %',q; end if;
end$$;
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1.5}]',1,10,100)$q$,'reward_invalid_quantity');
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1,"customizations":[{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc"},{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc"}]}]',1,10,100)$q$,'reward_duplicate_addon');
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1,"customizations":[{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}]}]',1,10,100)$q$,'reward_invalid_addon');
update menu set is_available=false;
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100)$q$,'reward_item_unavailable');
update menu set is_available=true;
update settings set delivery_fee='NaN';
select pg_temp.expect_error($q$select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100)$q$,'checkout_delivery_unavailable');
update settings set delivery_fee=2000;
insert into reward_campaigns values ('CHECKOUT',true,now()-interval '1 day',now()+interval '1 day',2000,0,1,10,false);
do $$declare q jsonb; before_count integer; begin
 select count(*) into before_count from reward_redemptions;
 q := quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100,'CHECKOUT');
 if q->>'total' <> '10000' then raise exception 'discount quote wrong'; end if;
 if (select count(*) from reward_redemptions) <> before_count then raise exception 'quote consumed reward'; end if;
end$$;
set role authenticated;
-- Quote is callable; configuration is not client writable/readable.
select quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100);
select pg_temp.expect_error($q$select * from checkout_service_wards$q$,'permission denied');
select pg_temp.expect_error($q$insert into checkout_service_wards values (101,true,'forged coverage',now())$q$,'permission denied');
select pg_temp.expect_error($q$insert into orders(id,items,total_price) values ('forged','[]',1)$q$,'permission denied');
select pg_temp.expect_error($q$update orders set total_price=1$q$,'permission denied');
select pg_temp.expect_error($q$delete from orders$q$,'permission denied');
reset role;
set role anon;
select pg_temp.expect_error($q$insert into orders(id,items,total_price) values ('anon-forged','[]',1)$q$,'permission denied');
select pg_temp.expect_error($q$select quote_checkout('[]',1,10,100)$q$,'permission denied');
reset role;
select set_config('request.jwt.claim.sub','',false);
select pg_temp.expect_error($q$select quote_checkout('[]',1,10,100)$q$,'checkout_session_required');
