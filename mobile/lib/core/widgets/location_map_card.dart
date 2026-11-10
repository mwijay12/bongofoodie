import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_tokens.dart';
import '../utils/map_links.dart';
import 'skeleton/skeleton_box.dart';

final mapTileProviderFactoryProvider = Provider<TileProvider Function()>(
    (ref) => () => NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance()));

final externalMapLauncherProvider = Provider<Future<bool> Function(Uri)>(
    (ref) => (uri) => launchUrl(uri,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank'));

/// Explicit tile consent. Map gestures are preview-only: never change saved address.
class LocationMapCard extends ConsumerStatefulWidget {
  const LocationMapCard({super.key, required this.sw, required this.target});
  final bool sw;
  final MapTarget target;
  @override
  ConsumerState<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends ConsumerState<LocationMapCard> {
  bool _loaded = false;
  bool _tileError = false;
  int _revision = 0;
  TileProvider? _tileProvider;
  static const _tileUrl = String.fromEnvironment('MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
  static const _attribution = String.fromEnvironment('MAP_ATTRIBUTION',
      defaultValue: '© OpenStreetMap contributors');
  static const _attributionUrl = String.fromEnvironment('MAP_ATTRIBUTION_URL',
      defaultValue: 'https://www.openstreetmap.org/copyright');

  Future<void> _open(Uri uri, {Uri? fallback}) async {
    final launch = ref.read(externalMapLauncherProvider);
    var opened = false;
    try {
      opened = await launch(uri);
    } catch (_) {/* Keep address entry usable. */}
    if (!opened && fallback != null) {
      try {
        opened = await launch(fallback);
      } catch (_) {/* Report below. */}
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.sw
            ? 'Ramani haijafunguka. Jaribu tena au tumia anwani iliyoandikwa.'
            : 'Could not open maps. Retry or use the written address.')));
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final target = widget.target;
    final point = target.hasCoordinates
        ? LatLng(target.latitude!, target.longitude!)
        : const LatLng(-6.7924, 39.2083);
    final tileUri = Uri.tryParse(_tileUrl);
    final configured =
        tileUri?.scheme == 'https' && (tileUri?.host.isNotEmpty ?? false);
    final revision = _revision;
    final buttonStyle = TextButton.styleFrom(
        minimumSize: const Size(AppSpace.huge, AppSpace.huge));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: AppSpace.md),
      Text(sw ? 'Ramani na programu za ramani' : 'Map and map apps',
          style: Theme.of(context).textTheme.titleMedium),
      Text(sw
          ? 'Kuangalia tu; ramani haibadili anwani wala kuthibitisha huduma ya kufikisha.'
          : 'Preview only; the map does not change your address or confirm delivery coverage.'),
      if (!_loaded) ...[
        Text(sw
            ? 'Ukipakia, mtoa ramani atapokea IP yako na eneo unaloangalia. Kufungua programu nyingine hushiriki anwani au mahali hapo nayo.'
            : 'Loading shares your IP and viewed area with the tile provider. Opening another map shares the address or coordinates with that provider.'),
        OutlinedButton.icon(
            key: const Key('load-location-map'),
            onPressed: () => setState(() => _loaded = true),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(AppSpace.huge, AppSpace.huge)),
            icon: const Icon(Icons.map_outlined),
            label: Text(sw ? 'Pakia ramani' : 'Load map')),
      ] else ...[
        Text(target.hasCoordinates
            ? (sw
                ? 'Alama ni mahali pa kifaa, si anwani iliyothibitishwa.'
                : 'Pin is the device fix, not a verified address.')
            : (sw
                ? 'Mtazamo wa Dar tu; anwani yako haijawekwa kwenye ramani.'
                : 'Dar reference view only; your address has not been placed on the map.')),
        if (configured && !_tileError)
          SizedBox(
              height: AppSpace.v220,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: FlutterMap(
                      key: ValueKey('$point/$_revision'),
                      options: MapOptions(
                          initialCenter: point,
                          initialZoom: target.hasCoordinates ? 16 : 11,
                          minZoom: 3,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.drag |
                                  InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom)),
                      children: [
                        TileLayer(
                            urlTemplate: _tileUrl,
                            userAgentPackageName:
                                'tz.co.bongofoodie (github.com/mwijay12/bongofoodie)',
                            panBuffer: 0,
                            tileProvider: _tileProvider ??=
                                ref.read(mapTileProviderFactoryProvider)(),
                            tileDisplay: const TileDisplay.instantaneous(),
                            errorTileCallback: (_, __, ___) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    revision == _revision &&
                                    !_tileError)
                                  setState(() => _tileError = true);
                              });
                            },
                            tileBuilder: (context, tile, image) =>
                                image.loadFinished == null
                                    ? const SkeletonBox(height: AppSpace.v220)
                                    : tile),
                        if (target.hasCoordinates)
                          MarkerLayer(markers: [
                            Marker(
                                point: point,
                                width: AppSpace.huge,
                                height: AppSpace.huge,
                                child: Icon(Icons.location_pin,
                                    size: AppSpace.huge,
                                    color:
                                        Theme.of(context).colorScheme.primary))
                          ]),
                      ]))),
        // Attribution stays visible outside the map viewport, including tile failure.
        TextButton(
            onPressed: () {
              final uri = Uri.tryParse(_attributionUrl);
              if (uri != null && uri.scheme == 'https') _open(uri);
            },
            style: buttonStyle,
            child: Text(_attribution)),
        if (_tileError || !configured) ...[
          Text(sw
              ? 'Ramani haijapatikana. Anwani na viungo vya ramani bado vinapatikana.'
              : 'Map unavailable. Address entry and external map links still work.'),
          TextButton(
              key: const Key('retry-location-map'),
              onPressed: () => setState(() {
                    _revision++;
                    _tileProvider = null;
                    _tileError = false;
                  }),
              style: buttonStyle,
              child: Text(sw ? 'Jaribu ramani tena' : 'Retry map')),
        ],
      ],
      Text(target.isEmpty
          ? (sw
              ? 'Andika anwani au pata mahali pa kifaa ili kufungua kwenye ramani.'
              : 'Enter an address or get a device fix to open it in maps.')
          : (target.hasCoordinates
              ? (sw ? 'Fungua mahali pa kifaa kwenye:' : 'Open device fix in:')
              : (sw
                  ? 'Tafuta anwani uliyoandika kwenye:'
                  : 'Search your entered address in:'))),
      Wrap(spacing: AppSpace.sm, children: [
        TextButton(
            onPressed: target.isEmpty
                ? null
                : () => _open(target.uri(MapDestination.google)),
            style: buttonStyle,
            child: const Text('Google Maps')),
        TextButton(
            onPressed: target.isEmpty
                ? null
                : () => _open(target.uri(MapDestination.openStreetMap)),
            style: buttonStyle,
            child: const Text('OpenStreetMap')),
        if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
          TextButton(
              onPressed: target.isEmpty
                  ? null
                  : () => _open(target.uri(MapDestination.apple)),
              style: buttonStyle,
              child: const Text('Apple Maps')),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          TextButton(
              onPressed: target.isEmpty
                  ? null
                  : () => _open(target.uri(MapDestination.device),
                      fallback: target.uri(MapDestination.openStreetMap)),
              style: buttonStyle,
              child: Text(sw ? 'Programu nyingine' : 'Other map apps')),
      ]),
    ]);
  }
}
