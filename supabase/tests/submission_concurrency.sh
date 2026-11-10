#!/usr/bin/env bash
# Isolated PostgreSQL fixture only, NEVER production. Real two-client contention.
set -euo pipefail
: "${DATABASE_URL:?Set an isolated test database URL}"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
update checkout_runtime set submission_enabled=true;
update checkout_service_wards set enabled=true where ward_code=100;
insert into reward_campaigns values ('SUBRACE',true,now()-interval '1 day',now()+interval '1 day',1000,0,1,1,false);
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
create table checkout_race_fixture(body jsonb);
insert into checkout_race_fixture select jsonb_build_object('version',1,'items',
 '[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]'::jsonb,
 'region',1,'district',10,'ward',100,'promo_code','SUBRACE','name','Asha Juma',
 'phone','+255712345678','address','TEST address only, House 14','payment_method','cash','notes','',
 'reviewed_quote',quote_checkout('[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',1,10,100,'SUBRACE'));
SQL
submit() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
select submit_checkout('20000000-0000-4000-8000-000000000001',(select body from checkout_race_fixture));
select pg_sleep(1);
commit;
SQL
}
submit > /tmp/checkout-race-one.log 2>&1 &
a=$!
submit > /tmp/checkout-race-two.log 2>&1 &
b=$!
first=0; second=0
wait "$a" || first=$?
wait "$b" || second=$?
cat /tmp/checkout-race-one.log /tmp/checkout-race-two.log
if [[ "$first" -ne 0 || "$second" -ne 0 ]]; then
  echo 'Identical concurrent requests must both return committed result' >&2; exit 1
fi
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
do $$declare oid text; begin
 select order_id into strict oid from checkout_requests where request_key='20000000-0000-4000-8000-000000000001';
 if (select count(*) from orders where id=oid)<>1 then raise exception 'duplicate order'; end if;
 if (select count(*) from reward_redemptions where code='SUBRACE')<>1 then raise exception 'duplicate redemption'; end if;
 if (select count(*) from achievement_events where event_type='order_submitted' and source_id=oid)<>1 then raise exception 'duplicate achievement'; end if;
end$$;
SQL
