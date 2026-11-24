import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_map.dart';

/// The arithmetic that keeps the card on its pin through a pan.
///
/// It replaced asking the map where a coordinate had landed, which cost a round trip per
/// frame and arrived late, so this is now the only thing placing the card while the camera
/// moves — and a projection that is wrong is a card that floats somewhere near its pin.
void main() {
  const view = Size(360, 800);
  // Malate, Manila.
  const lng = 120.9842;
  const lat = 14.5658;

  Offset at(
    double longitude,
    double latitude, {
    double zoom = 14,
    double centreLongitude = lng,
    double centreLatitude = lat,
  }) =>
      offsetOnMap(
        longitude: longitude,
        latitude: latitude,
        centreLongitude: centreLongitude,
        centreLatitude: centreLatitude,
        zoom: zoom,
        view: view,
      );

  test('what the camera is pointed at lands in the middle of the view', () {
    expect(at(lng, lat), const Offset(180, 400));
  });

  test('east is right and north is up', () {
    expect(at(lng + 0.01, lat).dx, greaterThan(180));
    expect(at(lng - 0.01, lat).dx, lessThan(180));
    expect(at(lng, lat + 0.01).dy, lessThan(400), reason: 'screen y grows downward');
    expect(at(lng, lat - 0.01).dy, greaterThan(400));
  });

  test('one zoom level in doubles the distance from the centre', () {
    final near = at(lng + 0.01, lat, zoom: 14).dx - 180;
    final close = at(lng + 0.01, lat, zoom: 15).dx - 180;
    expect(close, closeTo(near * 2, 0.001));
  });

  /// 512 logical pixels to the world at zoom 0 is the scale the map itself draws with. Half a
  /// world of longitude at zoom 1 is a quarter of that square: 256 pixels.
  test('the world is 512 logical pixels square at zoom 0', () {
    expect(at(90, 0, zoom: 1, centreLongitude: 0, centreLatitude: 0).dx - 180, closeTo(256, 1e-9));
  });

  /// A search in Fiji, a stay the other side of the date line. Measured the long way round it
  /// would be most of a world away and the card would be told its pin had left the screen.
  test('the antimeridian is crossed the short way', () {
    final offset = at(-179.9, -18, zoom: 10, centreLongitude: 179.9, centreLatitude: -18);
    expect(offset.dx - 180, greaterThan(0), reason: 'east of the camera, not a world west');
    expect(offset.dx - 180, lessThan(400), reason: '0.2° at zoom 10 is a few hundred pixels');
  });

  test('a pole does not run off to infinity', () {
    expect(at(0, 89.9, centreLongitude: 0, centreLatitude: 0).dy.isFinite, isTrue);
  });
}
