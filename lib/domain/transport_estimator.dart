import '../core/constants/kenya_locations.dart';

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
