import 'dart:math' show sin, cos, sqrt, atan2;
import '../core/constants/kenya_locations.dart';
import '../data/models/geo_location.dart';

/// Estimates transport distance and cost for an order.
///
/// Pure calculation. No side effects. Swappable for a real rate-card
/// integration later without touching any widget.
class TransportEstimator {
  TransportEstimator._();

  /// Base fee that applies regardless of distance (loading, admin overhead).
  static const double baseFeeKes = 500.0;

  /// Per-km rate for the straight-line estimate. Real road distance is
  /// typically 1.2–1.4x straight-line; the base fee compensates.
  static const double perKmKes = 45.0;

  /// Load factor: heavier loads cost more but sub-linearly, so a 10t
  /// load is not 10x a 1t load. Divisor of 10 means a 10t load doubles
  /// the per-km cost.
  static const double loadFactorDivisor = 10.0;

  /// Straight-line distance in km between pickup and delivery counties.
  static double distanceKm({
    required String pickupCounty,
    required String deliveryCounty,
  }) =>
      KenyaLocations.distanceKm(pickupCounty, deliveryCounty);

  /// Prefer point-to-point Haversine when both locations have coordinates.
  /// Falls back to county-centroid estimate when coordinates are missing.
  static double distanceKmForLocations(
    GeoLocation a,
    GeoLocation b,
  ) {
    if (a.hasCoordinates && b.hasCoordinates) {
      final lat1 = a.lat!;
      final lon1 = a.lng!;
      final lat2 = b.lat!;
      final lon2 = b.lng!;
      // Haversine formula
      const R = 6371.0; // Earth radius km
      final dLat = _deg2rad(lat2 - lat1);
      final dLon = _deg2rad(lon2 - lon1);
      final radLat1 = _deg2rad(lat1);
      final radLat2 = _deg2rad(lat2);
      final aH = (sin(dLat / 2) * sin(dLat / 2)) +
          (sin(dLon / 2) * sin(dLon / 2)) * cos(radLat1) * cos(radLat2);
      final c = 2 * atan2(sqrt(aH), sqrt(1 - aH));
      return R * c;
    }
    // Fallback to county centroid distance
    return KenyaLocations.distanceKm(a.county, b.county);
  }

  static double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  /// Estimated cost in KES for a given distance and load.
  /// Returns 0 when distance is unknown (unknown county).
  static double costKes({
    required String pickupCounty,
    required String deliveryCounty,
    required double quantityTonnes,
  }) {
    final d = distanceKm(
      pickupCounty: pickupCounty,
      deliveryCounty: deliveryCounty,
    );
    if (d == 0) return 0;
    final perKm = perKmKes * d;
    final loadFactor = 1 + (quantityTonnes / loadFactorDivisor);
    return (baseFeeKes + perKm) * loadFactor;
  }
}
