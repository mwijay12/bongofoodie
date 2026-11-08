class EnvConfig {
  EnvConfig._();

  static const int _showcaseLatencyMs =
      int.fromEnvironment('SHOWCASE_LATENCY_MS', defaultValue: 700);
  static Duration get showcaseLatency => hasSupabaseCredentials
      ? Duration.zero
      : Duration(milliseconds: _showcaseLatencyMs < 0 ? 0 : _showcaseLatencyMs);

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get supabaseAnonKey =>
      _publishableKey.trim().isNotEmpty ? _publishableKey.trim() : _anonKey.trim();

  static const String webApiBaseUrl = String.fromEnvironment(
    'WEB_API_BASE_URL',
    defaultValue: '',
  );

  static bool get isSupabaseConfigured {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey;
    return url.startsWith('https://') &&
        url.contains('.supabase.co') &&
        !url.contains('YOUR_PROJECT_REF') &&
        !url.contains('placeholder') &&
        key.length > 20 &&
        !key.contains('YOUR_SUPABASE') &&
        !key.contains('placeholder');
  }

  static bool get hasSupabaseCredentials => isSupabaseConfigured;

  static String get chefEdgeFunctionUrl {
    if (!isSupabaseConfigured) return '';
    final clean = supabaseUrl.endsWith('/')
        ? supabaseUrl.substring(0, supabaseUrl.length - 1)
        : supabaseUrl;
    return '$clean/functions/v1/chef-ai';
  }

  static const List<String> authorizedAdminEmails = [
    'defoodordering@gmail.com',
    'mwijaydavie@gmail.com',
    'davidbyanmwijage@gmail.com',
  ];
}
