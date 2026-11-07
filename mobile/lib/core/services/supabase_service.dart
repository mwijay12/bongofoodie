import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get isLive => _initialized && EnvConfig.isSupabaseConfigured;

  static SupabaseClient? get client => isLive ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (!EnvConfig.isSupabaseConfigured) {
      debugPrint(
        '[BongoFoodie] Running in Interactive Showcase Demo Mode '
        '(pass --dart-define=SUPABASE_URL=... & SUPABASE_ANON_KEY=... for live cloud mode).',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _initialized = true;
      // Fire non-blocking keep-alive heartbeat so active app launches also refresh DB activity
      pingKeepAlive();
    } catch (e) {
      debugPrint('[BongoFoodie] Supabase init warning, falling back to Showcase Mode: $e');
      _initialized = false;
    }
  }

  static Future<void> pingKeepAlive() async {
    final sb = client;
    if (sb == null) return;
    try {
      await sb.rpc('ping_keepalive', params: {'p_source': 'flutter-mobile-client'});
    } catch (_) {
      // Non-critical background ping
    }
  }
}
