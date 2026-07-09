import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://rkjanbxkgfyjpdcichvy.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// Lazy singleton: only create client when first accessed (never at module load time)
let _supabase: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (!_supabase) {
    const key = supabaseAnonKey || 'placeholder-key-for-build-only';
    _supabase = createClient(supabaseUrl, key);
  }
  return _supabase;
}

// Export a Proxy that lazily initializes the client on first property access
export const supabase = new Proxy<SupabaseClient>({} as SupabaseClient, {
  get(_target, prop) {
    return getClient()[prop as keyof SupabaseClient];
  },
});