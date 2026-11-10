import 'package:bongo_foodie/core/utils/map_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search strings are encoded, not concatenated into arbitrary URLs', () {
    const target = MapTarget(address: 'Mtaa A & B / near #14, Dar es Salaam');
    expect(target.uri(MapDestination.google).host, 'www.google.com');
    expect(target.uri(MapDestination.google).queryParameters['query'],
        target.address);
    expect(
        target.uri(MapDestination.apple).queryParameters['q'], target.address);
    expect(target.uri(MapDestination.openStreetMap).queryParameters['query'],
        target.address);
    expect(target.uri(MapDestination.device).scheme, 'geo');
  });
  test('device coordinate links point at the fix, not an invented address', () {
    const target = MapTarget(latitude: -6.8, longitude: 39.2);
    expect(target.uri(MapDestination.google).queryParameters['query'],
        '-6.8,39.2');
    expect(target.uri(MapDestination.openStreetMap).queryParameters['mlat'],
        '-6.8');
    expect(
        target.uri(MapDestination.openStreetMap).fragment, 'map=16/-6.8/39.2');
    expect(target.uri(MapDestination.device).path, '-6.8,39.2');
  });
  test('invalid coordinates cannot become map pins', () {
    expect(const MapTarget(latitude: 99, longitude: 2).hasCoordinates, isFalse);
    expect(const MapTarget(latitude: double.nan, longitude: 2).isEmpty, isTrue);
    expect(const MapTarget(address: '  ').isEmpty, isTrue);
  });
}
