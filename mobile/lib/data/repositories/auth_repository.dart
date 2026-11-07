import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';
import '../../core/services/supabase_service.dart';
import '../mock/showcase_seed_data.dart';
import '../models/models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  static const _demoUserKey = 'bongo_demo_user_v2';

  Future<AppUser?> restoreSession() async {
    final sb = SupabaseService.client;
    if (sb != null) {
      final session = sb.auth.currentSession;
      final user = session?.user;
      if (user != null) {
        return _mapSupabaseUser(sb, user);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final savedDemo = prefs.getString(_demoUserKey);
    if (savedDemo != null && savedDemo.isNotEmpty) {
      try {
        return AppUser.fromJson(jsonDecode(savedDemo) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }

  Future<AppUser> signInDemo(UserRole role) async {
    final profile = ShowcaseSeedData.demoProfiles[role] ??
        ShowcaseSeedData.demoProfiles[UserRole.customer]!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_demoUserKey, jsonEncode(profile.toJson()));
    return profile;
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final sb = SupabaseService.client;
    if (sb == null) {
      throw Exception(
        'Live Supabase keys are not set yet. Tap any 1-Click Showcase Role above to explore immediately!',
      );
    }

    final res = await sb.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Unable to sign in. Please verify your email and password.');
    }
    return _mapSupabaseUser(sb, user);
  }

  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final sb = SupabaseService.client;
    if (sb == null) {
      // Seamless Showcase registration when running before Supabase setup
      final demoUser = AppUser(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: EnvConfig.authorizedAdminEmails.contains(email.trim().toLowerCase())
            ? UserRole.admin
            : UserRole.customer,
        isDemo: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_demoUserKey, jsonEncode(demoUser.toJson()));
      return demoUser;
    }

    final res = await sb.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
      },
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Account registration failed.');
    }
    return _mapSupabaseUser(sb, user, fallbackName: name.trim(), fallbackPhone: phone.trim());
  }

  Future<void> signInWithGoogleOAuth() async {
    final sb = SupabaseService.client;
    if (sb == null) {
      throw Exception('Google OAuth requires live Supabase credentials. Use 1-Click Showcase Login for instant demo!');
    }
    await sb.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'bongo-foodie://auth-callback',
    );
  }

  Future<void> resetPassword(String email) async {
    final sb = SupabaseService.client;
    if (sb == null) {
      throw Exception('Configure SUPABASE_URL & SUPABASE_ANON_KEY to send live password recovery emails.');
    }
    await sb.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'bongo-foodie://reset-password',
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_demoUserKey);
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        await sb.auth.signOut();
      } catch (_) {}
    }
  }

  Future<AppUser> _mapSupabaseUser(
    SupabaseClient sb,
    User user, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    Map<String, dynamic>? row;
    try {
      row = await sb
          .from('profiles')
          .select('id, name, email, phone, avatar_url, role')
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {}

    final email = user.email ?? '';
    final roleFromDb = row?['role']?.toString();
    final role = roleFromDb != null
        ? UserRole.fromString(roleFromDb)
        : (EnvConfig.authorizedAdminEmails.contains(email.toLowerCase())
            ? UserRole.admin
            : UserRole.customer);

    return AppUser(
      id: user.id,
      name: (row?['name'] ??
              user.userMetadata?['full_name'] ??
              fallbackName ??
              email)
          .toString(),
      email: email,
      phone: (row?['phone'] ??
              user.userMetadata?['phone'] ??
              fallbackPhone ??
              '')
          .toString(),
      avatarUrl:
          (row?['avatar_url'] ?? user.userMetadata?['avatar_url'] ?? '').toString(),
      role: role,
      isDemo: false,
    );
  }
}
