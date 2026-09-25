import '../../domain/location_catalog.dart';

enum LocationSource { selfReported, deviceCaptured, adminVerified }

class GeoLocation {
  final String county;
  final String subCounty;
  final String area;
  final double? lat;
  final double? lng;
  final LocationSource source;

  GeoLocation({
    required this.county,
    required this.subCounty,
    required this.area,
    this.lat,
    this.lng,
    this.source = LocationSource.selfReported,
  }) {
    final countyValue = county.trim();
    final subCountyValue = subCounty.trim();
    if (countyValue.isEmpty || subCountyValue.isEmpty) {
      return;
    }

    final catalog = LocationCatalog.instanceOrNull;
    final valid = catalog?.isValidPair(countyValue, subCountyValue) ?? true;
    if (!valid) {
      throw ArgumentError(
        'Invalid county/sub-county pair: "$county" / "$subCounty"',
      );
    }
  }

  String get broadLocation => '$area, $subCounty';

  bool get hasCoordinates => lat != null && lng != null;

  static GeoLocation capture({
    required double lat,
    required double lng,
    String county = '',
    String subCounty = '',
    String area = '',
    LocationSource source = LocationSource.deviceCaptured,
  }) {
    return GeoLocation(
      county: county,
      subCounty: subCounty,
      area: area,
      lat: lat,
      lng: lng,
      source: source,
    );
  }
}
