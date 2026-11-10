import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env_config.dart';
import '../core/services/supabase_service.dart';
import 'auth_provider.dart';

class AchievementProgress {
  final int ordersSubmitted;
  final int correctQuizzes;
  const AchievementProgress(
      {this.ordersSubmitted = 0, this.correctQuizzes = 0});
  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! num ||
          !value.isFinite ||
          value < 0 ||
          value != value.roundToDouble()) {
        throw const FormatException('Invalid achievement count');
      }
      return value.toInt();
    }

    return AchievementProgress(
        ordersSubmitted: count('orders_submitted'),
        correctQuizzes: count('correct_quizzes'));
  }
  int get unlockedCount =>
      (ordersSubmitted >= 1 ? 1 : 0) +
      (ordersSubmitted >= 3 ? 1 : 0) +
      (correctQuizzes >= 1 ? 1 : 0);
}

final achievementsProvider =
    FutureProvider.autoDispose<AchievementProgress>((ref) async {
  final user = ref.watch(authProvider.select((s) => s.user));
  // Preview never derives awards from seeded orders, cached favorites or demo wins.
  if (user == null || user.isDemo || !EnvConfig.hasSupabaseCredentials) {
    return const AchievementProgress();
  }
  final client = SupabaseService.client;
  if (client == null || client.auth.currentUser?.id != user.id) {
    throw StateError('achievement_session_unavailable');
  }
  final response = await client.rpc('achievement_progress');
  return AchievementProgress.fromJson(
      Map<String, dynamic>.from(response as Map));
});
