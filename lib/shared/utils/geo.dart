/// Great-circle geometry for the map and flight tracking.
library;

import 'dart:math' as math;

/// Latitude and longitude in degrees.
typedef LatLng = (double lat, double lng);

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

const double _earthKm = 6371;

/// Great-circle distance in kilometres.
double distanceKm(LatLng a, LatLng b) {
  final dLat = _rad(b.$1 - a.$1);
  final dLng = _rad(b.$2 - a.$2);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.$1)) * math.cos(_rad(b.$1)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * _earthKm * math.asin(math.sqrt(h));
}

/// The point [km] from [from] on [bearingDeg] (0 = north, clockwise).
LatLng offsetKm(LatLng from, double km, double bearingDeg) {
  final d = km / _earthKm;
  final b = _rad(bearingDeg);
  final lat1 = _rad(from.$1);
  final lng1 = _rad(from.$2);
  final lat2 = math.asin(math.sin(lat1) * math.cos(d) + math.cos(lat1) * math.sin(d) * math.cos(b));
  final lng2 = lng1 + math.atan2(math.sin(b) * math.sin(d) * math.cos(lat1), math.cos(d) - math.sin(lat1) * math.sin(lat2));
  return (_deg(lat2), _deg(lng2));
}

/// The point a [fraction] (0–1) of the way from [a] to [b] along the great circle.
LatLng interpolate(LatLng a, LatLng b, double fraction) {
  final lat1 = _rad(a.$1), lng1 = _rad(a.$2), lat2 = _rad(b.$1), lng2 = _rad(b.$2);
  final d = distanceKm(a, b) / _earthKm;
  if (d == 0) return a;
  final f1 = math.sin((1 - fraction) * d) / math.sin(d);
  final f2 = math.sin(fraction * d) / math.sin(d);
  final x = f1 * math.cos(lat1) * math.cos(lng1) + f2 * math.cos(lat2) * math.cos(lng2);
  final y = f1 * math.cos(lat1) * math.sin(lng1) + f2 * math.cos(lat2) * math.sin(lng2);
  final z = f1 * math.sin(lat1) + f2 * math.sin(lat2);
  return (_deg(math.atan2(z, math.sqrt(x * x + y * y))), _deg(math.atan2(y, x)));
}
