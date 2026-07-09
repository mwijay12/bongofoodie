import * as WebBrowser from 'expo-web-browser';
import * as Linking from 'expo-linking';
import { makeRedirectUri } from 'expo-auth-session';
import { supabase } from './supabase';
import { CreateUserParams, SignInParams } from "@/type";

// Complete session callbacks on Web
WebBrowser.maybeCompleteAuthSession();

export async function signInWithGoogle() {
  try {
    const redirectUri = makeRedirectUri({
      scheme: 'bongo-foodie',
      path: 'auth-callback',
    });

    console.log(`[Google OAuth Request] Redirect URI: ${redirectUri}`);

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: redirectUri,
        skipBrowserRedirect: true, // Let Expo WebBrowser handle the navigation
      },
    });

    if (error) throw error;
    if (!data?.url) throw new Error("Supabase OAuth URL is empty");

    // Open standard secure WebBrowser sheet
    const res = await WebBrowser.openAuthSessionAsync(data.url, redirectUri);

    if (res.type === 'success' && res.url) {
      // Standard OAuth params are returned in Hash. Replace # with ? to parse via expo-auth-session
      const parsedUrl = res.url.replace('#', '?');
      const params = Linking.parse(parsedUrl);
      const queryParams = params.queryParams || {};
      
      const access_token = Array.isArray(queryParams.access_token) 
        ? queryParams.access_token[0] 
        : queryParams.access_token;
      const refresh_token = Array.isArray(queryParams.refresh_token) 
        ? queryParams.refresh_token[0] 
        : queryParams.refresh_token;

      if (access_token && refresh_token) {
        const { data: sessionData, error: sessionError } = await supabase.auth.setSession({
          access_token,
          refresh_token,
        });

        if (sessionError) throw sessionError;
        console.log(`[Google OAuth Success] User authenticated: ${sessionData.user?.email}`);
        return sessionData.user;
      }
    }
    return null;
  } catch (error) {
    console.error("[Google OAuth Error] Process failed:", error);
    throw error;
  }
}

export async function signUpWithEmail({ email, password, name }: CreateUserParams, phone?: string) {
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: name,
          phone: phone || '',
        },
      },
    });
    if (error) throw error;
    return data.user;
  } catch (error) {
    console.error("[Supabase SignUp Error]", error);
    throw error;
  }
}

export async function signInWithEmail({ email, password }: SignInParams) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    return data.user;
  } catch (error) {
    console.error("[Supabase SignIn Error]", error);
    throw error;
  }
}

export async function signOutUser() {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  } catch (error) {
    console.error("[Supabase SignOut Error]", error);
    throw error;
  }
}

export async function resetPasswordForEmail(email: string) {
  try {
    const redirectUri = makeRedirectUri({
      scheme: 'bongo-foodie',
      path: 'reset-password',
    });

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: redirectUri,
    });

    if (error) throw error;
    return true;
  } catch (error) {
    console.error("[Supabase ResetPassword Error]", error);
    throw error;
  }
}
