import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://rkjanbxkgfyjpdcichvy.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// Lazy initialization: only create client when first accessed
let supabaseInstance: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!supabaseInstance) {
    if (!supabaseAnonKey) {
      console.warn('[Supabase] NEXT_PUBLIC_SUPABASE_ANON_KEY not defined. Using placeholder key.');
    }
    supabaseInstance = createClient(supabaseUrl, supabaseAnonKey || 'placeholder-key-for-build');
  }
  return supabaseInstance;
}

// Re-export as `supabase` for convenience
export const supabase = supabaseAnonKey 
  ? createClient(supabaseUrl, supabaseAnonKey)
  : createClient(supabaseUrl, 'placeholder-key-for-build');