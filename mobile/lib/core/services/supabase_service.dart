import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Why the app is or is not talking to Supabase. Surfaced in the UI so a
/// failure is never silently reported as "check your connection".
enum SupabaseStatus {
  /// Credentials are present and the client is live.
  live,

  /// No credentials compiled in: intentional showcase/demo mode.
  showcase,

  /// Credentials are present but initialisation failed. The message carries
  /// the underlying reason.
  failed,
}

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static SupabaseStatus _status = SupabaseStatus.showcase;
  static String _failureReason = '';

  static bool get isLive => _initialized && EnvConfig.isSupabaseConfigured;

  static SupabaseStatus get status =>
      !EnvConfig.isSupabaseConfigured ? SupabaseStatus.showcase : _status;

  /// Non-empty only when [status] is [SupabaseStatus.failed].
  static String get failureReason => _failureReason;

  static SupabaseClient? get client => isLive ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (!EnvConfig.isSupabaseConfigured) {
      _status = SupabaseStatus.showcase;
      debugPrint(
        '[BongoFoodie] Running in Interactive Showcase Demo Mode '
        '(pass --dart-define=SUPABASE_URL=... & SUPABASE_PUBLISHABLE_KEY=... for live cloud mode).',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _initialized = true;
      _status = SupabaseStatus.live;
      _failureReason = '';
      // Fire non-blocking keep-alive heartbeat so active app launches also refresh DB activity
      pingKeepAlive();
    } catch (e, stack) {
      _initialized = false;
      _status = SupabaseStatus.failed;
      _failureReason = e.toString();
      debugPrint('[BongoFoodie] Supabase init FAILED: $e');
      debugPrint('$stack');
    }
  }

  /// Retries initialisation after a failure. Returns true when live.
  static Future<bool> retry() async {
    if (_initialized) return true;
    _status = SupabaseStatus.showcase;
    _failureReason = '';
    await initialize();
    return _initialized;
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
