import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/config/env_config.dart';
import 'pending_checkout.dart';

/// Explicitly constructed only after deployment/guest/address gates are resolved.
/// Does not initialize auth, sign in anonymously, insert orders or retry writes.
class SupabaseCheckoutTransport implements CheckoutTransport {
  SupabaseCheckoutTransport(this.owner);
  @override
  final String owner;
  @override
  String get project => EnvConfig.supabaseUrl;
  SupabaseClient get client =>
      SupabaseService.client ??
      (throw StateError('checkout_backend_unavailable'));
  void _authorize() {
    if (client.auth.currentUser?.id != owner) {
      throw StateError('checkout_owner_unavailable');
    }
  }

  @override
  Future<Map<String, dynamic>> submit(
      String key, Map<String, dynamic> request) async {
    _authorize();
    final result = await client
        .rpc('submit_checkout', params: {'p_key': key, 'p_request': request});
    _authorize();
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>?> lookup(String key) async {
    _authorize();
    final result = await client.rpc('lookup_checkout', params: {'p_key': key});
    _authorize();
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }
}
