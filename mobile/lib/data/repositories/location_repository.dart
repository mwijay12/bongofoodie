import 'dart:convert';
import '../../state/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';
import '../mock/showcase_seed_data.dart';
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
  static const _prefKey = 'bongo_delivery_address_v2';

  DeliveryAddressNotifier() : super('Kijitonyama, Kinondoni, Dar es Salaam') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (mounted && saved != null && saved.trim().isNotEmpty) {
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
    await setAddress(address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'bongo_location_selection_v1',
        jsonEncode({
          'version': 1,
          'region': region,
          'district': district,
          'ward': ward,
          'street': street,
        }));
  }

  Future<void> clearPrivateAddress() async {
    state = 'Kijitonyama, Kinondoni, Dar es Salaam';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await prefs.remove('bongo_location_selection_v1');
  }

  Future<void> setAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, trimmed);
  }
}

class LocationRepository {
  Future<List<TzRegion>> getRegions() async {
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        final rows = await sb
            .from('regions')
            .select('region_code, region_name')
            .order('region_name', ascending: true);
        if (rows.isNotEmpty) {
          return rows
              .map<TzRegion>((r) => TzRegion(
                    code: (r['region_code'] as num).toInt(),
                    name: r['region_name'].toString(),
                  ))
              .toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.regions;
  }

  Future<List<TzDistrict>> getDistricts(int regionCode) async {
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        final rows = await sb
            .from('districts')
            .select('district_code, district_name')
            .eq('region_id', regionCode)
            .order('district_name', ascending: true);
        if (rows.isNotEmpty) {
          return rows
              .map<TzDistrict>((r) => TzDistrict(
                    code: (r['district_code'] as num).toInt(),
                    name: r['district_name'].toString(),
                    regionCode: regionCode,
                  ))
              .toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.districts
        .where((d) => d.regionCode == regionCode)
        .toList();
  }

  Future<List<TzWard>> getWards(int districtCode) async {
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        final rows = await sb
            .from('wards')
            .select('ward_code, ward_name')
            .eq('district_id', districtCode)
            .order('ward_name', ascending: true);
        if (rows.isNotEmpty) {
          return rows
              .map<TzWard>((r) => TzWard(
                    code: (r['ward_code'] as num).toInt(),
                    name: r['ward_name'].toString(),
                    districtCode: districtCode,
                  ))
              .toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.wards
        .where((w) => w.districtCode == districtCode)
        .toList();
  }
}
