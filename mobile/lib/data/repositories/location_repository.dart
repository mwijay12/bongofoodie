import 'dart:convert';
import '../../state/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';
import '../mock/dar_location_reference.dart';
import '../../core/config/env_config.dart';
import '../models/models.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final deliveryAddressProvider =
    StateNotifierProvider<DeliveryAddressNotifier, String>((ref) {
  final notifier = DeliveryAddressNotifier();
  ref.listen<String?>(authProvider.select((a) => a.user?.id), (old, next) {
    if (old != null && old != next) notifier.clearPrivateAddress();
  });
  return notifier;
});

class DeliveryAddressNotifier extends StateNotifier<String> {
  static String get selectionSource => EnvConfig.hasSupabaseCredentials
      ? 'live:${EnvConfig.supabaseUrl}'
      : 'demo:dar-reference-v1';
  static const _prefKey = 'bongo_delivery_address_v2';

  DeliveryAddressNotifier() : super('') {
    _load();
  }

  int _revision = 0;

  Future<void> _load() async {
    final revision = _revision;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (mounted &&
        revision == _revision &&
        saved != null &&
        saved.trim().isNotEmpty) {
      state = saved;
    }
  }

  Future<Map<String, dynamic>?> readSelection() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('bongo_location_selection_v1');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data['version'] == 1 ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelection(
      {required int region,
      required int district,
      required int ward,
      required String street,
      required String address}) async {
    final revision = _revision + 1;
    await setAddress(address);
    if (revision != _revision) return;
    final prefs = await SharedPreferences.getInstance();
    if (revision != _revision) return;
    await prefs.setString(
        'bongo_location_selection_v1',
        jsonEncode({
          'version': 1,
          'source': selectionSource,
          'region': region,
          'district': district,
          'ward': ward,
          'street': street,
        }));
  }

  Future<void> saveManualAddress(String address) async {
    final revision = _revision + 1;
    await setAddress(address);
    final prefs = await SharedPreferences.getInstance();
    if (revision == _revision)
      await prefs.remove('bongo_location_selection_v1');
  }

  Future<void> clearPrivateAddress() async {
    _revision++;
    state = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await prefs.remove('bongo_location_selection_v1');
  }

  Future<void> setAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    final revision = ++_revision;
    final prefs = await SharedPreferences.getInstance();
    if (revision == _revision) await prefs.setString(_prefKey, trimmed);
  }
}

class LocationRepository {
  static const _timeout = Duration(seconds: 10);
  void _requireDemo() {
    if (EnvConfig.hasSupabaseCredentials) {
      throw StateError('location_catalog_unavailable');
    }
  }

  Future<List<TzRegion>> getRegions() async {
    final sb = SupabaseService.client;
    if (sb == null) {
      _requireDemo();
      return DarLocationReference.regions;
    }
    final rows = await sb
        .from('regions')
        .select('region_code, region_name')
        .order('region_name')
        .timeout(_timeout);
    return rows
        .map((r) => TzRegion(
            code: (r['region_code'] as num).toInt(),
            name: r['region_name'].toString()))
        .toList();
  }

  Future<List<TzDistrict>> getDistricts(int regionCode) async {
    final sb = SupabaseService.client;
    if (sb == null) {
      _requireDemo();
      return DarLocationReference.districts
          .where((d) => d.regionCode == regionCode)
          .toList();
    }
    final rows = await sb
        .from('districts')
        .select('district_code, district_name')
        .eq('region_id', regionCode)
        .order('district_name')
        .timeout(_timeout);
    return rows
        .map((r) => TzDistrict(
            code: (r['district_code'] as num).toInt(),
            name: r['district_name'].toString(),
            regionCode: regionCode))
        .toList();
  }

  Future<List<TzWard>> getWards(int districtCode) async {
    final sb = SupabaseService.client;
    if (sb == null) {
      _requireDemo();
      return DarLocationReference.wards
          .where((w) => w.districtCode == districtCode)
          .toList();
    }
    final rows = await sb
        .from('wards')
        .select('ward_code, ward_name')
        .eq('district_id', districtCode)
        .order('ward_name')
        .timeout(_timeout);
    return rows
        .map((r) => TzWard(
            code: (r['ward_code'] as num).toInt(),
            name: r['ward_name'].toString(),
            districtCode: districtCode))
        .toList();
  }
}
