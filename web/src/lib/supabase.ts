import { createClient, SupabaseClient } from '@supabase/supabase-js';

const rawUrl = (process.env.NEXT_PUBLIC_SUPABASE_URL || '').trim();
const rawAnonKey = (
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  ''
).trim();

export const isSupabaseConfigured =
  rawUrl.startsWith('https://') &&
  rawUrl.includes('.supabase.co') &&
  !rawUrl.includes('placeholder') &&
  !rawUrl.includes('YOUR_PROJECT_REF') &&
  rawAnonKey.length > 20 &&
  !rawAnonKey.includes('placeholder') &&
  !rawAnonKey.includes('YOUR_SUPABASE');

const supabaseUrl = isSupabaseConfigured ? rawUrl : 'https://placeholder.supabase.co';
const supabaseAnonKey = isSupabaseConfigured ? rawAnonKey : 'placeholder-anon-key-showcase-mode';

let _supabase: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (!_supabase) {
    _supabase = createClient(supabaseUrl, supabaseAnonKey);
  }
  return _supabase;
}

export const supabase = new Proxy<SupabaseClient>({} as SupabaseClient, {
  get(_target, prop) {
    return getClient()[prop as keyof SupabaseClient];
  },
});
