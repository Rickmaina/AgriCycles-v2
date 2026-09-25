import 'package:agricycles/data/models/geo_location.dart';
import 'package:agricycles/domain/transport_estimator.dart';

double landedCostPerUnit({
  required double pricePerUnit,
  required double quantity,
  required double estimatedTransportCost,
}) {
  if (quantity == 0) return double.infinity;
  return pricePerUnit + (estimatedTransportCost / quantity);
}

/// Helper that estimates transport cost (KES) between two locations and
/// returns the per-order transport estimate. Prefers Haversine when
/// coordinates are present; falls back to county centroid.
double estimateTransportKesForOrder({
  required GeoLocation pickup,
  required GeoLocation delivery,
  required double quantity,
}) {
  if (pickup.hasCoordinates && delivery.hasCoordinates) {
    final d = TransportEstimator.distanceKmForLocations(pickup, delivery);
    final perKm = TransportEstimator.perKmKes * d;
    final loadFactor = 1 + (quantity / TransportEstimator.loadFactorDivisor);
    return (TransportEstimator.baseFeeKes + perKm) * loadFactor;
  }
  return TransportEstimator.costKes(
    pickupCounty: pickup.county,
    deliveryCounty: delivery.county,
    quantityTonnes: quantity,
  );
}
