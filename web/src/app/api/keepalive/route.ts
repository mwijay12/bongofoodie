import { NextResponse } from 'next/server';
import { isSupabaseConfigured } from '@/lib/supabase';

/**
 * GET / POST `/api/keepalive`
 * Invoked automatically every day by Vercel Cron (`web/vercel.json`) and optionally
 * by uptime monitors to guarantee Supabase Free Tier never pauses from inactivity.
 */
async function handleKeepAlive(source: string) {
  const url = (process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || '').replace(/\/$/, '');
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    '';

  if (!isSupabaseConfigured || !url || !key) {
    return NextResponse.json({
      ok: true,
      mode: 'showcase-demo',
      message: 'Supabase environment variables not yet configured; Showcase fallback mode is active.',
      timestamp: new Date().toISOString(),
    });
  }

  try {
    // 1. Call `ping_keepalive` RPC (performs an actual Postgres UPSERT + SELECT)
    const rpcRes = await fetch(`${url}/rest/v1/rpc/ping_keepalive`, {
      method: 'POST',
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_source: source }),
      cache: 'no-store',
    });

    if (rpcRes.ok) {
      const heartbeat = await rpcRes.json();
      return NextResponse.json({
        ok: true,
        mode: 'supabase-live',
        heartbeat,
        timestamp: new Date().toISOString(),
      });
    }

    // 2. Fallback read query against `public.menu`
    const menuRes = await fetch(`${url}/rest/v1/menu?select=id&limit=1`, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
      cache: 'no-store',
    });

    return NextResponse.json({
      ok: menuRes.ok,
      mode: 'supabase-rest-fallback',
      status: menuRes.status,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Keep-alive ping failed',
        timestamp: new Date().toISOString(),
      },
      { status: 500 },
    );
  }
}

export async function GET() {
  return handleKeepAlive('vercel-cron-get');
}

export async function POST() {
  return handleKeepAlive('external-webhook-post');
}
