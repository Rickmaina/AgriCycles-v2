import '../../data/models/geo_location.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/transport_estimator.dart';

GeoLocation? viewerLocationOf(UserModel? user) {
  final county = user?.county?.trim() ?? '';
  final sub = user?.subCounty?.trim() ?? '';
  if (county.isEmpty || sub.isEmpty) return null;
  try {
    return GeoLocation(
      county: county,
      subCounty: sub,
      area: user?.area ?? '',
    );
  } catch (_) {
    return null;
  }
}

/// Farmer presentation: "30 km away", else the county name.
String farmerDistanceLabel({
  required ListingModel listing,
  GeoLocation? from,
}) {
  if (from == null || from.county.isEmpty) return listing.county;
  try {
    final km = TransportEstimator.distanceKmForLocations(from, listing.location);
    if (km <= 0) return listing.county;
    return '${km.round()} km away';
  } catch (_) {
    return listing.county;
  }
}
