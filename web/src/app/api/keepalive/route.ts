import { NextResponse } from 'next/server';

/**
 * GET / POST `/api/keepalive`
 * Invoked daily by Vercel Cron and optionally by uptime monitors. Server-only
 * environment variables are enough here: the client-side `isSupabaseConfigured`
 * flag must not decide whether a server heartbeat is sent.
 */
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const REQUEST_TIMEOUT_MS = 10_000;

function json(body: unknown, status = 200) {
  return NextResponse.json(body, {
    status,
    headers: { 'Cache-Control': 'no-store' },
  });
}

function resolveSupabaseConfig(): { url: string; key: string } | null {
  const url = (
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    ''
  )
    .trim()
    .replace(/\/+$/, '');
  const key = (
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    ''
  ).trim();

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }

  const hostIsSupabase = /^[a-z0-9-]+\.supabase\.co$/i.test(parsed.hostname);
  const urlIsReal =
    parsed.protocol === 'https:' &&
    hostIsSupabase &&
    !/YOUR_PROJECT_REF|placeholder|example\.com/i.test(url);
  const keyIsReal =
    key.length > 20 &&
    !/YOUR_SUPABASE|placeholder|CHANGE_ME|example/i.test(key);

  return urlIsReal && keyIsReal ? { url, key } : null;
}

function assertCronAuthorized(request: Request) {
  const secret = process.env.CRON_SECRET?.trim();
  if (!secret) return null;
  if (request.headers.get('authorization') !== `Bearer ${secret}`) {
    return json(
      {
        ok: false,
        mode: 'unauthorized',
        message: 'A valid cron bearer token is required for this endpoint.',
        timestamp: new Date().toISOString(),
      },
      401,
    );
  }
  return null;
}

async function handleKeepAlive(source: string, request: Request) {
  const unauthorized = assertCronAuthorized(request);
  if (unauthorized) return unauthorized;

  const config = resolveSupabaseConfig();
  if (!config) {
    return json(
      {
        ok: false,
        mode: 'not-configured',
        message: 'Set a real Supabase URL and key in the server environment before relying on this heartbeat.',
        timestamp: new Date().toISOString(),
      },
      503,
    );
  }

  const { url, key } = config;
  const authHeaders = {
    apikey: key,
    Authorization: `Bearer ${key}`,
  };

  try {
    // 1. Call `ping_keepalive` RPC: a real Postgres UPSERT plus SELECT.
    const rpcRes = await fetch(`${url}/rest/v1/rpc/ping_keepalive`, {
      method: 'POST',
      headers: { ...authHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_source: source }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      cache: 'no-store',
    });

    if (rpcRes.ok) {
      const heartbeat = await rpcRes.json().catch(() => null);
      return json({
        ok: true,
        mode: 'supabase-live',
        heartbeat,
        timestamp: new Date().toISOString(),
      });
    }

    // 2. A plain read still counts as database activity.
    const menuRes = await fetch(`${url}/rest/v1/menu?select=id&limit=1`, {
      headers: authHeaders,
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      cache: 'no-store',
    });

    if (menuRes.ok) {
      return json({
        ok: true,
        mode: 'supabase-rest-fallback',
        rpcStatus: rpcRes.status,
        status: menuRes.status,
        timestamp: new Date().toISOString(),
      });
    }

    // 3. Prove the project itself is awake; fail loudly when the schema is missing.
    const healthRes = await fetch(`${url}/auth/v1/health`, {
      headers: { apikey: key },
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      cache: 'no-store',
    });

    return json(
      {
        ok: false,
        mode: healthRes.ok ? 'supabase-schema-missing' : 'supabase-unreachable',
        rpcStatus: rpcRes.status,
        menuStatus: menuRes.status,
        healthStatus: healthRes.status,
        message: healthRes.ok
          ? 'The project answered but ping_keepalive and the menu table did not. Apply supabase/schema.sql.'
          : 'Supabase did not answer the heartbeat, menu read, or auth health check.',
        timestamp: new Date().toISOString(),
      },
      healthRes.ok ? 503 : 502,
    );
  } catch (error) {
    return json(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Keep-alive ping failed',
        timestamp: new Date().toISOString(),
      },
      500,
    );
  }
}

export async function GET(request: Request) {
  return handleKeepAlive('vercel-cron-get', request);
}

export async function POST(request: Request) {
  return handleKeepAlive('external-webhook-post', request);
}
