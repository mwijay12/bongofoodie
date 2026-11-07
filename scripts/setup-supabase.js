#!/usr/bin/env node
/**
 * Bongo Foodie v2 — One-Command Supabase Provisioner
 *
 * Usage:
 *   1. Copy `.env.example` to `.env` and fill in your new Supabase credentials.
 *   2. Run `npm run supabase:setup`
 *
 * Note: If you prefer zero database-pooler configuration, you can also paste
 * `supabase/schema.sql` directly into the Supabase Dashboard -> SQL Editor -> Run,
 * and then run `npm run supabase:users` to create demo/admin accounts!
 */

const fs = require('fs');
const path = require('path');

function loadEnv() {
  const candidates = [
    path.join(__dirname, '../.env'),
    path.join(__dirname, '../web/.env.local'),
  ];
  for (const envPath of candidates) {
    if (!fs.existsSync(envPath)) continue;
    const content = fs.readFileSync(envPath, 'utf8');
    for (const line of content.split(/\r?\n/)) {
      const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
      if (!match) continue;
      const key = match[1];
      let val = (match[2] || '').trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (!process.env[key]) process.env[key] = val;
    }
  }
}

loadEnv();

const supabaseUrl =
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  process.env.EXPO_PUBLIC_SUPABASE_URL ||
  '';
const anonKey =
  process.env.SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ||
  '';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const managementToken = process.env.SUPABASE_ACCESS_TOKEN || '';
const poolerUrl = process.env.SUPABASE_POOLER_URL || '';

const usersOnly = process.argv.includes('--users-only');

async function runSchemaMigration() {
  if (usersOnly) return;

  const sql = fs.readFileSync(path.join(__dirname, '../supabase/schema.sql'), 'utf8');

  // Option A: Execute via Supabase Management API when SUPABASE_ACCESS_TOKEN (`sbp_...`) is provided
  if (managementToken && supabaseUrl) {
    const match = supabaseUrl.match(/https:\/\/([a-z0-9-]+)\.supabase\.co/i);
    if (match) {
      const projectRef = match[1];
      console.log(`🔌 Applying supabase/schema.sql to project '${projectRef}' via Supabase Management API...`);
      const res = await fetch(`https://api.supabase.com/v1/projects/${projectRef}/database/query`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${managementToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: sql }),
      });
      if (!res.ok) {
        const errBody = await res.text();
        throw new Error(`Supabase Management API SQL failed (${res.status}): ${errBody}`);
      }
      console.log('✅ `supabase/schema.sql` executed via Management API (tables, RLS, buckets, TZ locations & Swahili menu seeded)!\n');
      return;
    }
  }

  if (!poolerUrl) {
    console.log('ℹ️  Neither SUPABASE_ACCESS_TOKEN nor SUPABASE_POOLER_URL set — skipping direct SQL push.');
    console.log('   👉 Paste `supabase/schema.sql` into Supabase Dashboard -> SQL Editor -> Run (takes 3 seconds!).\n');
    return;
  }

  let Client;
  try {
    ({ Client } = require('pg'));
  } catch {
    console.error('❌ `pg` package not installed. Run `npm install` in root first.');
    process.exit(1);
  }

  const client = new Client({
    connectionString: poolerUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    console.log('🔌 Connecting to Supabase PostgreSQL via SUPABASE_POOLER_URL...');
    await client.connect();
    await client.query(sql);
    console.log('✅ `supabase/schema.sql` executed (tables, RLS, triggers, buckets, TZ locations & menu seeded)!\n');
  } finally {
    await client.end().catch(() => {});
  }
}

async function seedAuthAccounts() {
  if (!supabaseUrl || !serviceRoleKey) {
    console.log('ℹ️  SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing — skipping demo/admin Auth user creation.');
    return;
  }

  const { createClient } = require('@supabase/supabase-js');
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (!process.env.ADMIN_PASSWORD || !process.env.DEMO_PASSWORD) {
    console.log('ℹ️  Set ADMIN_PASSWORD and DEMO_PASSWORD to seed accounts; skipping Auth seeding.');
    return;
  }

  const accounts = [
    {
      email: process.env.ADMIN_EMAIL || 'mwijaydavie@gmail.com',
      password: process.env.ADMIN_PASSWORD,
      name: 'Mwijay Davie (Admin)',
      phone: '+255790942616',
      role: 'admin',
    },
    {
      email: 'waiter@bongofoodie.co.tz',
      password: process.env.DEMO_PASSWORD,
      name: 'Salma Rashid (Waiter)',
      phone: '+255788123456',
      role: 'waiter',
    },
    {
      email: 'demo@bongofoodie.co.tz',
      password: process.env.DEMO_PASSWORD,
      name: 'Amina Juma (Customer)',
      phone: '+255712345678',
      role: 'customer',
    },
  ];

  console.log('👤 Ensuring showcase & admin Auth accounts exist...');
  for (const acc of accounts) {
    const { data, error } = await supabase.auth.admin.createUser({
      email: acc.email,
      password: acc.password,
      email_confirm: true,
      user_metadata: { full_name: acc.name, phone: acc.phone, role: acc.role },
    });

    if (error && !/already/i.test(error.message)) {
      console.warn(`   ⚠️  Could not create ${acc.email}: ${error.message}`);
      continue;
    }

    // Ensure role is updated in public.profiles
    if (data?.user?.id) {
      await supabase.from('profiles').upsert({
        id: data.user.id,
        name: acc.name,
        email: acc.email,
        phone: acc.phone,
        role: acc.role,
        updated_at: new Date().toISOString(),
      });
    }
    console.log(`   ✅ Ready: ${acc.email} [${acc.role}]`);
  }
}

async function verifyKeepAlive() {
  const keyToUse = anonKey || serviceRoleKey;
  if (!supabaseUrl || !keyToUse) return;

  console.log('\n💓 Testing Keep-Alive Heartbeat RPC (`ping_keepalive`)...');
  const res = await fetch(`${supabaseUrl.replace(/\/$/, '')}/rest/v1/rpc/ping_keepalive`, {
    method: 'POST',
    headers: {
      apikey: keyToUse,
      Authorization: `Bearer ${keyToUse}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ p_source: 'setup-script' }),
  });

  if (res.ok) {
    const body = await res.json();
    console.log('   ✅ Keep-Alive active:', JSON.stringify(body));
  } else {
    console.warn(`   ⚠️  Keep-Alive RPC returned HTTP ${res.status}. Make sure supabase/schema.sql has been executed.`);
  }
}

(async () => {
  console.log('🍲 Bongo Foodie v2 — Supabase Setup Starting...\n');
  await runSchemaMigration();
  await seedAuthAccounts();
  await verifyKeepAlive();
  console.log('\n🎉 Done! Your Supabase backend is ready for Flutter (`mobile/`) and Next.js (`web/`).');
})().catch((err) => {
  console.error('❌ Setup failed:', err);
  process.exit(1);
});
