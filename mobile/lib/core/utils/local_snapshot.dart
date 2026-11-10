import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Versioned public-data snapshot. Never use it to acknowledge an order/payment.
class LocalSnapshot {
  LocalSnapshot({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  static const freshness = Duration(minutes: 15);
  static const retention = Duration(days: 7);

  Future<void> write(String key, Object data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'bongo_snapshot_v1:$key',
        jsonEncode({
          'version': 1,
          'savedAt': _now().toUtc().toIso8601String(),
          'data': data,
        }));
  }

  Future<SnapshotValue?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'bongo_snapshot_v1:$key';
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final age =
          _now().toUtc().difference(DateTime.parse(json['savedAt'] as String));
      if (json['version'] != 1 || age.isNegative || age > retention) {
        await prefs.remove(storageKey);
        return null;
      }
      return SnapshotValue(json['data'], age > freshness);
    } catch (_) {
      await prefs.remove(storageKey);
      return null;
    }
  }
}

class SnapshotValue {
  const SnapshotValue(this.data, this.stale);
  final dynamic data;
  final bool stale;
}
