#!/usr/bin/env node
/**
 * Bongo Foodie — Zero-Dependency Supabase Keep-Alive Ping
 * Prevents Supabase Free Tier projects from pausing after 7 days of inactivity.
 *
 * Environment variables:
 *   SUPABASE_URL       (or NEXT_PUBLIC_SUPABASE_URL)
 *   SUPABASE_ANON_KEY  (or NEXT_PUBLIC_SUPABASE_ANON_KEY)
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

async function ping() {
  if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables.');
    process.exit(1);
  }

  console.log(`💓 Pinging Supabase Keep-Alive at ${supabaseUrl} (source: ${source})...`);

  // 1. Execute write+read heartbeat RPC
  const rpcRes = await fetch(`${supabaseUrl}/rest/v1/rpc/ping_keepalive`, {
    method: 'POST',
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ p_source: source }),
  });

  if (rpcRes.ok) {
    const data = await rpcRes.json();
    console.log('✅ Heartbeat RPC succeeded:', JSON.stringify(data));
    return;
  }

  console.warn(`⚠️ RPC returned ${rpcRes.status}; falling back to REST menu read query...`);

  // 2. Fallback read query against public.menu in case RPC wasn't created yet
  const restRes = await fetch(`${supabaseUrl}/rest/v1/menu?select=id,name&limit=1`, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
    },
  });

  if (!restRes.ok) {
    const text = await restRes.text();
    throw new Error(`Supabase REST check failed (${restRes.status}): ${text}`);
  }

  const items = await restRes.json();
  console.log(`✅ Fallback REST query succeeded (${items.length} row(s) returned).`);
}

ping().catch((err) => {
  console.error('❌ Keep-Alive failed:', err.message);
  process.exit(1);
});
