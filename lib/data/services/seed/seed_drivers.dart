import '../../models/driver_profile.dart';
import '../../models/geo_location.dart';

class SeedDrivers {
  SeedDrivers._();

  static final List<DriverProfile> all = [
    DriverProfile(
      id: 'd1',
      driverId: 'drv1',
      driverName: 'Driver One',
      baseLocation: GeoLocation(
        county: 'Nairobi',
        subCounty: 'Central',
        area: 'Depot A',
        lat: -1.2921,
        lng: 36.8219,
        source: LocationSource.deviceCaptured,
      ),
      createdAt: DateTime.now(),
    ),
    DriverProfile(
      id: 'd2',
      driverId: 'drv2',
      driverName: 'Driver Two',
      baseLocation: GeoLocation(
        county: 'Kakamega',
        subCounty: 'Lurambi',
        area: 'Depot B',
        lat: null,
        lng: null,
        source: LocationSource.selfReported,
      ),
      createdAt: DateTime.now(),
    ),
    DriverProfile(
      id: 'd3',
      driverId: 'drv3',
      driverName: 'Driver Three',
      baseLocation: GeoLocation(
        county: 'Kisumu',
        subCounty: 'Nyando',
        area: 'Depot C',
        lat: -0.0910,
        lng: 34.7110,
        source: LocationSource.adminVerified,
      ),
      createdAt: DateTime.now(),
    ),
  ];
}
