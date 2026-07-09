import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://rkjanbxkgfyjpdcichvy.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

if (!supabaseAnonKey) {
  console.warn('[Supabase Client Warning] NEXT_PUBLIC_SUPABASE_ANON_KEY environment variable is not defined.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
