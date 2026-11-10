/// External maps are searches/previews, never serviceability or address validation.
enum MapDestination { google, apple, openStreetMap, device }

class MapTarget {
  const MapTarget({this.latitude, this.longitude, this.address = ''});
  final double? latitude;
  final double? longitude;
  final String address;
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
  bool get isEmpty => !hasCoordinates && address.trim().isEmpty;
  String get query => hasCoordinates ? '$latitude,$longitude' : address.trim();
  Uri uri(MapDestination destination) {
    switch (destination) {
      case MapDestination.google:
        return Uri.https(
            'www.google.com', '/maps/search/', {'api': '1', 'query': query});
      case MapDestination.apple:
        return Uri.https('maps.apple.com', '/', {'q': query});
      case MapDestination.openStreetMap:
        if (hasCoordinates) {
          return Uri.https('www.openstreetmap.org', '/', {
            'mlat': '$latitude',
            'mlon': '$longitude'
          }).replace(fragment: 'map=16/$latitude/$longitude');
        }
        return Uri.https('www.openstreetmap.org', '/search', {'query': query});
      case MapDestination.device:
        return Uri(
            scheme: 'geo',
            path: hasCoordinates ? '$latitude,$longitude' : '0,0',
            queryParameters: {'q': query});
    }
  }
}
