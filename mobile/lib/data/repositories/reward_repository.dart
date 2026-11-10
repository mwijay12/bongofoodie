import '../../core/config/env_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/models.dart';

class RewardQuote {
  final String code;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  const RewardQuote(
      {required this.code,
      required this.subtotal,
      required this.deliveryFee,
      required this.discount});
  factory RewardQuote.fromJson(Map<String, dynamic> json) => RewardQuote(
      code: json['code'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble());
}

class RewardRepository {
  Future<RewardQuote> quote(String code, List<CartItemModel> items) async {
    final client = SupabaseService.client;
    if (!EnvConfig.hasSupabaseCredentials || client?.auth.currentUser == null) {
      throw StateError('reward_sign_in_required');
    }
    final json = await client.rpc('quote_reward', params: {
      'p_code': code.trim().toUpperCase(),
      'p_items': items.map((i) => i.toJson()).toList(),
    });
    return RewardQuote.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
