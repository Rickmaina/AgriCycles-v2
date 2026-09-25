import 'package:flutter_test/flutter_test.dart';
import 'package:agricycles/domain/transport_estimator.dart';
import 'package:agricycles/data/models/geo_location.dart';
import 'package:agricycles/core/constants/kenya_locations.dart';

void main() {
  test('Haversine used when both locations have coordinates', () {
    final nairobi = GeoLocation(
      county: 'Nairobi',
      subCounty: '',
      area: '',
      lat: -1.2921,
      lng: 36.8219,
      source: LocationSource.deviceCaptured,
    );
    final mombasa = GeoLocation(
      county: 'Mombasa',
      subCounty: '',
      area: '',
      lat: -4.0435,
      lng: 39.6682,
      source: LocationSource.deviceCaptured,
    );
    final d = TransportEstimator.distanceKmForLocations(nairobi, mombasa);
    expect(d, greaterThan(400));
    expect(d, lessThan(500));
  });

  test('Falls back to county centroid when coordinates missing', () {
    final a = GeoLocation(county: 'Kiambu', subCounty: '', area: '');
    final b = GeoLocation(county: 'Kisumu', subCounty: '', area: '');
    final d = TransportEstimator.distanceKmForLocations(a, b);
    expect(d, KenyaLocations.distanceKm(a.county, b.county));
  });
}
