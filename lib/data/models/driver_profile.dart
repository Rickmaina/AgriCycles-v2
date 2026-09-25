import 'geo_location.dart';

class DriverProfile {
  final String id;
  final String driverId;
  final String driverName;
  final GeoLocation baseLocation;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DriverProfile({
    required this.id,
    required this.driverId,
    required this.driverName,
    GeoLocation? baseLocation,
    String? county,
    String? subCounty,
    String? area,
    double? lat,
    double? lng,
    LocationSource source = LocationSource.selfReported,
    required this.createdAt,
    this.updatedAt,
  }) : baseLocation = baseLocation ??
            GeoLocation(
              county: county ?? '',
              subCounty: subCounty ?? '',
              area: area ?? '',
              lat: lat,
              lng: lng,
              source: source,
            );

  bool get hasCoordinates => baseLocation.hasCoordinates;

  String get broadLocation => baseLocation.broadLocation;

  DriverProfile copyWith({
    String? driverName,
    GeoLocation? baseLocation,
    DateTime? updatedAt,
  }) {
    return DriverProfile(
      id: id,
      driverId: driverId,
      driverName: driverName ?? this.driverName,
      baseLocation: baseLocation ?? this.baseLocation,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
