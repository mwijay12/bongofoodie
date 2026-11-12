#!/usr/bin/env node
/**
 * Bongo Foodie — Zero-Dependency Supabase Keep-Alive Ping
 * Prevents Supabase Free Tier projects from pausing after 7 days of inactivity.
 *
 * Environment variables:
 *   SUPABASE_URL       (or NEXT_PUBLIC_SUPABASE_URL)
 *   SUPABASE_ANON_KEY  (or SUPABASE_PUBLISHABLE_KEY, ...)
 *
 * Three independent pokes, in order of strength:
 *   1. POST /rest/v1/rpc/ping_keepalive  - real INSERT .. ON CONFLICT UPDATE
 *   2. GET  /rest/v1/menu?select=id      - read that still counts as activity
 *   3. GET  /auth/v1/health              - proves the project itself is awake
 *
 * Step 3 matters on a brand-new project: if the schema has not been applied
 * yet, steps 1 and 2 legitimately fail, but the project is NOT paused and the
 * date-poke in step 3 still counts as activity. Only if all three fail is the
 * project actually unreachable.
 */

const supabaseUrl = (
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  ''
).replace(/\/$/, '');

const supabaseKey =
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  '';

const source = process.env.KEEPALIVE_SOURCE || 'github-actions-cron';

const TIMEOUT_MS = 30000;

async function hit(path, init = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(`${supabaseUrl}${path}`, {
      ...init,
      signal: controller.signal,
      cache: 'no-store',
    });
    const text = await res.text();
    return { status: res.status, ok: res.ok, text };
  } catch (err) {
    const reason = err.name === 'AbortError' ? `timed out after ${TIMEOUT_MS}ms` : err.message;
    return { status: 0, ok: false, text: reason };
  } finally {
    clearTimeout(timer);
  }
}

const authHeaders = {
  apikey: supabaseKey,
  Authorization: `Bearer ${supabaseKey}`,
};

function brief(text, max = 300) {
  const compact = String(text || '').replace(/\s+/g, ' ').trim();
  return compact.length > max ? `${compact.slice(0, max)}...` : compact;
}

async function ping() {
  if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables.');
    process.exit(1);
  }

  console.log(`💓 Keep-alive target: ${supabaseUrl} (source: ${source})`);

  const failures = [];

  // 1. Strongest: an actual write through the RPC.
  const rpc = await hit('/rest/v1/rpc/ping_keepalive', {
    method: 'POST',
    headers: { ...authHeaders, 'Content-Type': 'application/json' },
    body: JSON.stringify({ p_source: source }),
  });
  if (rpc.ok) {
    console.log(`✅ Heartbeat RPC succeeded: ${brief(rpc.text)}`);
    return;
  }
  console.warn(`⚠️  RPC ping_keepalive -> HTTP ${rpc.status}: ${brief(rpc.text)}`);
  failures.push(`rpc(ping_keepalive)=${rpc.status}`);

  // 2. A plain read still registers database activity.
  const menu = await hit('/rest/v1/menu?select=id&limit=1', { headers: authHeaders });
  if (menu.ok) {
    console.log(`✅ Fallback menu read succeeded: ${brief(menu.text)}`);
    return;
  }
  console.warn(`⚠️  REST menu read -> HTTP ${menu.status}: ${brief(menu.text)}`);
  failures.push(`rest(menu)=${menu.status}`);

  // 3. Prove the project is awake even when the schema is missing.
  const health = await hit('/auth/v1/health', { headers: { apikey: supabaseKey } });
  if (health.ok) {
    console.log(`✅ Project is awake (auth health ${health.status}), but the schema is not applied yet.`);
    console.log(`ℹ️  Run the "Supabase database setup" workflow to create tables and the ping_keepalive function.`);
    console.log(`ℹ️  The project itself responded, so it is not paused. Failing so the missing schema gets fixed.`);
    console.error(`❌ Keep-alive could not write. Signs of life: auth-health=200, ${failures.join(', ')}`);
    process.exit(1);
  }
  console.warn(`⚠️  Auth health -> HTTP ${health.status}: ${brief(health.text)}`);
  failures.push(`auth-health=${health.status}`);

  throw new Error(
    `Supabase is unreachable on all three probes (${failures.join(', ')}). ` +
      `The project may be paused, or the URL/key secret is wrong.`
  );
}

ping().catch((err) => {
  console.error('❌ Keep-Alive failed:', err.message);
  process.exit(1);
});
