#!/usr/bin/env bash
# Isolated fixture DB only. Runs two independent clients, competing for one slot.
set -euo pipefail
: "${DATABASE_URL:?Set an isolated rewards test database URL}"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
insert into reward_campaigns values ('RACE',true,now()-interval '1 day',now()+interval '1 day',2000,0,1,1,false);
SQL
place() {
  local user="$1" order="$2"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
begin;
select set_config('request.jwt.claim.sub', '$user', true);
insert into orders(id,profile_id,items,total_price,promo_code) values ('$order','$user','[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","quantity":1}]',10000,'RACE');
select pg_sleep(1);
commit;
SQL
}
place 11111111-1111-1111-1111-111111111111 race-one > /tmp/reward-race-one.log 2>&1 &
a=$!
place 22222222-2222-2222-2222-222222222222 race-two > /tmp/reward-race-two.log 2>&1 &
b=$!
first=0; second=0
wait "$a" || first=$?
wait "$b" || second=$?
cat /tmp/reward-race-one.log /tmp/reward-race-two.log
if [[ "$first" -eq 0 && "$second" -eq 0 ]] || [[ "$first" -ne 0 && "$second" -ne 0 ]]; then
  echo 'Expected exactly one successful transaction' >&2; exit 1
fi
grep -q reward_limit_reached /tmp/reward-race-*.log
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
do $$begin
 if (select count(*) from reward_redemptions where code='RACE') <> 1 then raise exception 'race ledger count'; end if;
 if (select count(*) from orders where promo_code='RACE') <> 1 then raise exception 'race order count'; end if;
end$$;
SQL
