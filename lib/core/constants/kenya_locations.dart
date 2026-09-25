// DEPRECATED — kept for backward compatibility only.
//
// The county list now lives in `assets/data/kenya_locations.json`
// loaded via `lib/domain/location_catalog.dart`. New code should
// call `LocationCatalog.instance.counties` instead.
//
// This shim exists because `TransportEstimator` still imports it for
// centroid-based distance calculation. Migrate both and delete this
// file in a follow-up cleanup.

import 'dart:math' as math;

import '../../domain/location_catalog.dart';

/// @Deprecated Use LocationCatalog instead for the county list.
@Deprecated('Use LocationCatalog.instance.counties instead')
class KenyaLocations {
  KenyaLocations._();

  /// Reads the canonical list from the loaded catalog.
  /// Throws if `LocationCatalog.load()` has not completed yet.
  static List<String> get counties => LocationCatalog.instance.counties;

  /// County centroids used by TransportEstimator for straight-line
  /// distance estimation. Not survey-grade — good enough for planning.
  static const Map<String, ({double lat, double lng})> countyCentroids = {
    'Nairobi':  (lat: -1.2921, lng: 36.8219),
    'Kiambu':   (lat: -1.1714, lng: 36.8356),
    'Kisumu':   (lat: -0.0917, lng: 34.7680),
    'Nakuru':   (lat: -0.3031, lng: 36.0800),
    'Mombasa':  (lat: -4.0435, lng: 39.6682),
    'Machakos': (lat: -1.5177, lng: 37.2634),
    'Kajiado':  (lat: -1.8521, lng: 36.7768),
    'Kakamega': (lat:  0.2827, lng: 34.7519),
  };

  /// Straight-line distance in km between two county centroids.
  /// Returns 0 if either county is unknown.
  static double distanceKm(String from, String to) {
    final a = countyCentroids[from];
    final b = countyCentroids[to];
    if (a == null || b == null) return 0;

    const earthRadiusKm = 6371.0;
    final dLat = _toRad(b.lat - a.lat);
    final dLng = _toRad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(a.lat)) *
            math.cos(_toRad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  static double _toRad(double degrees) => degrees * math.pi / 180.0;
}
