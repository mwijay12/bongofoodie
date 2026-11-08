import '../theme/app_tokens.dart';
import 'app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/repositories/location_repository.dart';
import '../theme/app_colors.dart';

Future<String?> showTanzaniaLocationPicker(BuildContext context) {
  return showAppSheet<String>(
    context,
    showDragHandle: true,
    builder: (_) => const TanzaniaLocationSheet(),
  );
}

class TanzaniaLocationSheet extends ConsumerStatefulWidget {
  const TanzaniaLocationSheet({super.key});

  @override
  ConsumerState<TanzaniaLocationSheet> createState() =>
      _TanzaniaLocationSheetState();
}

class _TanzaniaLocationSheetState extends ConsumerState<TanzaniaLocationSheet> {
  List<TzRegion> _regions = const [];
  List<TzDistrict> _districts = const [];
  List<TzWard> _wards = const [];

  TzRegion? _selectedRegion;
  TzDistrict? _selectedDistrict;
  TzWard? _selectedWard;
  final _streetCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(locationRepositoryProvider);
    final regions = await repo.getRegions();
    TzRegion? defaultReg = regions.isNotEmpty ? regions.first : null;
    for (final r in regions) {
      if (r.name.toLowerCase().contains('dar')) {
        defaultReg = r;
        break;
      }
    }

    List<TzDistrict> districts = const [];
    TzDistrict? defaultDist;
    List<TzWard> wards = const [];
    TzWard? defaultWard;

    if (defaultReg != null) {
      districts = await repo.getDistricts(defaultReg.code);
      defaultDist = districts.isNotEmpty ? districts.first : null;
      if (defaultDist != null) {
        wards = await repo.getWards(defaultDist.code);
        defaultWard = wards.isNotEmpty ? wards.first : null;
      }
    }

    if (mounted) {
      setState(() {
        _regions = regions;
        _selectedRegion = defaultReg;
        _districts = districts;
        _selectedDistrict = defaultDist;
        _wards = wards;
        _selectedWard = defaultWard;
        _loading = false;
      });
    }
  }

  Future<void> _onRegionChanged(TzRegion? reg) async {
    if (reg == null) return;
    setState(() {
      _selectedRegion = reg;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = const [];
      _wards = const [];
    });
    final repo = ref.read(locationRepositoryProvider);
    final dists = await repo.getDistricts(reg.code);
    final firstDist = dists.isNotEmpty ? dists.first : null;
    final wards =
        firstDist != null ? await repo.getWards(firstDist.code) : <TzWard>[];
    if (mounted) {
      setState(() {
        _districts = dists;
        _selectedDistrict = firstDist;
        _wards = wards;
        _selectedWard = wards.isNotEmpty ? wards.first : null;
      });
    }
  }

  Future<void> _onDistrictChanged(TzDistrict? dist) async {
    if (dist == null) return;
    setState(() {
      _selectedDistrict = dist;
      _selectedWard = null;
      _wards = const [];
    });
    final wards = await ref.read(locationRepositoryProvider).getWards(dist.code);
    if (mounted) {
      setState(() {
        _wards = wards;
        _selectedWard = wards.isNotEmpty ? wards.first : null;
      });
    }
  }

  void _confirmAddress() {
    final parts = <String>[
      if (_streetCtrl.text.trim().isNotEmpty) _streetCtrl.text.trim(),
      if (_selectedWard != null) _selectedWard!.name,
      if (_selectedDistrict != null) _selectedDistrict!.name,
      if (_selectedRegion != null) _selectedRegion!.name,
    ];
    final formatted =
        parts.isNotEmpty ? parts.join(', ') : 'Kijitonyama, Dar es Salaam';
    ref.read(deliveryAddressProvider.notifier).setAddress(formatted);
    Navigator.pop(context, formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.v22,
        AppSpace.v4,
        AppSpace.v22,
        MediaQuery.of(context).viewInsets.bottom + AppSpace.v26,
      ),
      child: _loading
          ? const SizedBox(
              height: AppSpace.v220,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpace.v8),
                    Text(
                      'Select Delivery Location (Tanzania)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.v16),
                DropdownButtonFormField<TzRegion>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region (Mkoa)',
                  ),
                  items: _regions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name),
                          ))
                      .toList(),
                  onChanged: _onRegionChanged,
                ),
                const SizedBox(height: AppSpace.v12),
                DropdownButtonFormField<TzDistrict>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District (Wilaya)',
                  ),
                  items: _districts
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name),
                          ))
                      .toList(),
                  onChanged: _onDistrictChanged,
                ),
                const SizedBox(height: AppSpace.v12),
                DropdownButtonFormField<TzWard>(
                  value: _selectedWard,
                  decoration: const InputDecoration(
                    labelText: 'Ward (Kata)',
                  ),
                  items: _wards
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(w.name),
                          ))
                      .toList(),
                  onChanged: (w) => setState(() => _selectedWard = w),
                ),
                const SizedBox(height: AppSpace.v12),
                TextField(
                  controller: _streetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Street / Landmark (Mtaa au Jengo)',
                    hintText: 'e.g. Near Mlimani City Gate 2, House #14',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                ),
                const SizedBox(height: AppSpace.v20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmAddress,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Save Delivery Location'),
                  ),
                ),
              ],
            ),
    );
  }
}
