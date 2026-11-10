import 'location_map_card.dart';
import '../utils/map_links.dart';
import '../../data/repositories/foreground_location_repository.dart';
import '../theme/app_tokens.dart';
import '../theme/app_colors.dart';
import 'app_sheet.dart';
import 'skeleton/skeleton_box.dart';
import '../../state/settings_provider.dart';
import '../../data/mock/dar_location_reference.dart';
import '../../core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/repositories/location_repository.dart';

Future<String?> showTanzaniaLocationPicker(BuildContext context) =>
    showAppSheet<String>(context,
        showDragHandle: true, builder: (_) => const TanzaniaLocationSheet());

class TanzaniaLocationSheet extends ConsumerStatefulWidget {
  const TanzaniaLocationSheet({super.key});
  @override
  ConsumerState<TanzaniaLocationSheet> createState() => _LocationState();
}

class _LocationState extends ConsumerState<TanzaniaLocationSheet> {
  List<TzRegion> _regions = [];
  List<TzDistrict> _districts = [];
  List<TzWard> _wards = [];
  TzRegion? _region;
  TzDistrict? _district;
  TzWard? _ward;
  final _street = TextEditingController();
  final _manual = TextEditingController();
  bool _manualMode = false;
  bool _loading = true;
  bool _error = false;
  bool _saving = false;
  bool _locating = false;
  LocationFix? _fix;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _initial();
  }

  @override
  void dispose() {
    _request++;
    _street.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _initial() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final repo = ref.read(locationRepositoryProvider);
      final stored =
          await ref.read(deliveryAddressProvider.notifier).readSelection();
      final saved = stored?['source'] == DeliveryAddressNotifier.selectionSource
          ? stored
          : null;
      final regions = await repo.getRegions();
      TzRegion? region;
      for (final r in regions) {
        if (r.code == saved?['region']) region = r;
      }
      final districts = region == null
          ? <TzDistrict>[]
          : await repo.getDistricts(region.code);
      TzDistrict? district;
      for (final d in districts) {
        if (d.code == saved?['district']) district = d;
      }
      final wards =
          district == null ? <TzWard>[] : await repo.getWards(district.code);
      TzWard? ward;
      for (final w in wards) {
        if (w.code == saved?['ward']) ward = w;
      }
      if (!mounted || request != _request) return;
      setState(() {
        _regions = regions;
        _region = region;
        _districts = districts;
        _district = district;
        _wards = wards;
        _ward = ward;
        if (ward != null) {
          _street.text = (saved?['street'] ?? '').toString();
        } else if (_manual.text.isEmpty) {
          final address = ref.read(deliveryAddressProvider);
          if (address.isNotEmpty) {
            _manualMode = true;
            _manual.text = address;
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeRegion(TzRegion? value) async {
    final request = ++_request;
    setState(() {
      _region = value;
      _district = null;
      _ward = null;
      _districts = [];
      _wards = [];
      _street.clear();
      _loading = true;
      _error = false;
    });
    try {
      final rows = value == null
          ? <TzDistrict>[]
          : await ref.read(locationRepositoryProvider).getDistricts(value.code);
      if (mounted && request == _request) {
        setState(() {
          _districts = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _changeDistrict(TzDistrict? value) async {
    final request = ++_request;
    setState(() {
      _district = value;
      _ward = null;
      _wards = [];
      _street.clear();
      _loading = true;
      _error = false;
    });
    try {
      final rows = value == null
          ? <TzWard>[]
          : await ref.read(locationRepositoryProvider).getWards(value.code);
      if (mounted && request == _request) {
        setState(() {
          _wards = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _locate() async {
    if (_locating || _saving) return;
    setState(() {
      _locating = true;
      _fix = null;
    });
    final fix = await ref.read(foregroundLocationProvider).locate();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _fix = fix;
    });
  }

  String _fixMessage(bool sw) {
    switch (_fix!.outcome) {
      case LocationOutcome.available:
        final coords =
            '${_fix!.latitude!.toStringAsFixed(5)}, ${_fix!.longitude!.toStringAsFixed(5)}';
        final accuracy = _fix!.accuracy!.ceil();
        return sw
            ? 'Mahali pa kifaa: $coords (usahihi takriban mita $accuracy). Jaza anwani mwenyewe; kata na huduma ya kufikisha bado hazijathibitishwa.'
            : 'Device location: $coords (reported accuracy about $accuracy m). Enter your address; ward and delivery coverage are still unverified.';
      case LocationOutcome.denied:
        return sw
            ? 'Ruhusa haijatolewa. Unaweza kujaribu tena au kuandika anwani.'
            : 'Permission denied. Retry or enter your address manually.';
      case LocationOutcome.deniedForever:
        return sw
            ? 'Ruhusa imezuiwa. Badili ruhusa kwenye mipangilio ya kifaa au andika anwani.'
            : 'Permission blocked. Change device settings or enter your address manually.';
      case LocationOutcome.servicesOff:
        return sw
            ? 'Huduma ya mahali imezimwa. Iwashe kwenye kifaa kisha jaribu tena, au andika anwani.'
            : 'Location services are off. Enable them on your device and retry, or enter your address manually.';
      case LocationOutcome.inaccurate:
        return sw
            ? 'Usahihi wa mahali ni mdogo. Jaribu tena au andika anwani; hakuna kata iliyochaguliwa.'
            : 'Location accuracy is low. Retry or enter your address; no ward was selected.';
      case LocationOutcome.unavailable:
        return sw
            ? 'Mahali hapajapatikana. Jaribu tena au andika anwani.'
            : 'Location unavailable. Retry or enter your address manually.';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_manualMode
        ? _manual.text.trim().length < 10
        : (_loading ||
            _error ||
            _region == null ||
            _district == null ||
            _ward == null ||
            _street.text.trim().isEmpty)) {
      return;
    }
    final notifier = ref.read(deliveryAddressProvider.notifier);
    setState(() => _saving = true);
    final address = _manualMode
        ? _manual.text.trim()
        : [_street.text.trim(), _ward!.name, _district!.name, _region!.name]
            .join(', ');
    try {
      if (_manualMode) {
        await notifier.saveManualAddress(address);
      } else {
        await notifier.saveSelection(
            region: _region!.code,
            district: _district!.code,
            ward: _ward!.code,
            street: _street.text.trim(),
            address: address);
      }
      if (mounted) Navigator.pop(context, address);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        final sw = ref.read(appStringsProvider).isSw;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(sw
                ? 'Anwani haijahifadhiwa. Jaribu tena.'
                : 'Could not save address. Please retry.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = ref.watch(appStringsProvider).isSw;
    final canSave = !_saving &&
        !_locating &&
        (_manualMode
            ? _manual.text.trim().length >= 10
            : !_loading &&
                !_error &&
                _ward != null &&
                _street.text.trim().isNotEmpty);
    return SingleChildScrollView(
        child: Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpace.screenH,
          AppSpace.sm,
          AppSpace.screenH,
          MediaQuery.viewInsetsOf(context).bottom + AppSpace.xl),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sw ? 'Mahali pa kufikisha' : 'Delivery location',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpace.sm),
            Text(sw
                ? 'Anwani si uthibitisho wa eneo la huduma. Mahali pa kifaa ni hiari; ruhusa itaombwa ukibonyeza hapa chini.'
                : 'An address does not confirm delivery coverage. Device location is optional and only requested when you tap below.'),
            if (!EnvConfig.hasSupabaseCredentials)
              Text(sw
                  ? 'Orodha ya Dar ni sehemu tu; namba ni za ndani ya programu.'
                  : 'Partial Dar reference list; IDs are internal app identifiers.'),
            OutlinedButton.icon(
                key: const Key('use-current-location'),
                onPressed: _locating || _saving ? null : _locate,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
                icon: const Icon(Icons.my_location_outlined),
                label:
                    Text(sw ? 'Tumia mahali nilipo' : 'Use current location')),
            if (_locating)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: SkeletonLines(count: 2)),
            if (_fix != null) ...[
              Semantics(liveRegion: true, child: Text(_fixMessage(sw))),
              if (_fix!.outcome == LocationOutcome.available)
                TextButton(
                    onPressed: () => setState(() => _fix = null),
                    style: TextButton.styleFrom(
                        minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
                    child: Text(sw
                        ? 'Tumia anwani niliyoandika badala yake'
                        : 'Use my entered address instead')),
              if (_fix!.outcome == LocationOutcome.deniedForever)
                TextButton(
                    onPressed: () async {
                      final opened = await ref
                          .read(foregroundLocationProvider)
                          .openSettings();
                      if (!mounted || opened) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(sw
                              ? 'Fungua mipangilio ya kifaa mwenyewe.'
                              : 'Please open device settings manually.')));
                    },
                    style: TextButton.styleFrom(
                        minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
                    child: Text(sw ? 'Fungua mipangilio' : 'Open settings')),
            ],
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    sw ? 'Andika anwani mwenyewe' : 'Enter address manually'),
                value: _manualMode,
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _manualMode = value;
                          if (value && _manual.text.isEmpty) {
                            _manual.text = ref.read(deliveryAddressProvider);
                          }
                        })),
            if (_manualMode)
              TextField(
                  key: const Key('manual-address'),
                  controller: _manual,
                  maxLines: 4,
                  minLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      labelText: sw ? 'Anwani kamili' : 'Full address',
                      helperText: sw
                          ? 'Mkoa, wilaya, kata, mtaa/jengo na alama ya karibu; angalau herufi 10.'
                          : 'Region, district, ward, street/building and landmark; at least 10 characters.',
                      helperMaxLines: 4))
            else ...[
              DropdownButtonFormField<TzRegion>(
                  key: const Key('location-region'),
                  value: _region,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: sw ? 'Mkoa' : 'Region'),
                  items: _regions
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r.name)))
                      .toList(),
                  onChanged: _saving ? null : _changeRegion),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<TzDistrict>(
                  key: const Key('location-district'),
                  value: _district,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText:
                          sw ? 'Wilaya / halmashauri' : 'District / council'),
                  items: _districts
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d.name)))
                      .toList(),
                  onChanged: _loading || _saving ? null : _changeDistrict),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<TzWard>(
                  key: const Key('location-ward'),
                  value: _ward,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: sw ? 'Kata' : 'Ward'),
                  items: _wards
                      .map((w) =>
                          DropdownMenuItem(value: w, child: Text(w.name)))
                      .toList(),
                  onChanged: _loading || _saving
                      ? null
                      : (w) => setState(() {
                            _ward = w;
                            _street.clear();
                          })),
              if (_ward != null &&
                  !EnvConfig.hasSupabaseCredentials &&
                  DarLocationReference.placesByWard.containsKey(_ward!.code))
                Text(
                    '${sw ? "Mfano wa eneo, si kata" : "Place example, not a ward"}: ${DarLocationReference.placesByWard[_ward!.code]!.join(", ")}'),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: SkeletonLines(count: 3)),
              if (_error)
                TextButton(
                    onPressed: _initial,
                    style: TextButton.styleFrom(
                        minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
                    child: Text(sw
                        ? 'Orodha haijapatikana. Jaribu tena au andika anwani.'
                        : 'Could not load list. Retry or enter address manually.')),
              if (!_loading &&
                  !_error &&
                  (_regions.isEmpty ||
                      (_region != null && _districts.isEmpty) ||
                      (_district != null && _wards.isEmpty)))
                Text(sw
                    ? 'Hakuna orodha hapa. Andika anwani mwenyewe.'
                    : 'No list here. Enter your address manually.'),
              const SizedBox(height: AppSpace.md),
              TextField(
                  controller: _street,
                  onChanged: (_) => setState(() {}),
                  maxLength: 240,
                  decoration: InputDecoration(
                      labelText: sw
                          ? 'Mtaa / jengo / alama ya karibu'
                          : 'Street / building / landmark')),
            ],
            LocationMapCard(
                sw: sw,
                target: _fix?.outcome == LocationOutcome.available
                    ? MapTarget(
                        latitude: _fix!.latitude, longitude: _fix!.longitude)
                    : MapTarget(
                        address: _manualMode
                            ? _manual.text.trim()
                            : [
                                _street.text.trim(),
                                if (_ward != null) _ward!.name,
                                if (_district != null) _district!.name,
                                if (_region != null) _region!.name
                              ].where((s) => s.isNotEmpty).join(', '))),
            const SizedBox(height: AppSpace.lg),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    key: const Key('save-location'),
                    onPressed: canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
                    child: Text(_saving
                        ? (sw ? 'Inahifadhi...' : 'Saving...')
                        : (sw ? 'Hifadhi anwani' : 'Save address')))),
          ]),
    ));
  }
}
