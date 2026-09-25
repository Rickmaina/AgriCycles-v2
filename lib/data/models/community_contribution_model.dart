import '../../core/constants/enums.dart';
import 'geo_location.dart';

/// One farmer's commitment to a community pre-order. The buyer accepts
/// each contribution individually — committed quantity can be rejected
/// or reduced on quality confirmation.
class CommunityContributionModel {
  final String id;
  final String preOrderId;
  final String farmerId;
  final String farmerName;

  final double committedQuantity;
  final double? acceptedQuantity; // set after buyer review
  final double pricePerUnit; // locked at commit time

  final GeoLocation pickupLocation;

  final ContributionStatus status;
  final DateTime createdAt;

  CommunityContributionModel({
    required this.id,
    required this.preOrderId,
    required this.farmerId,
    required this.farmerName,
    required this.committedQuantity,
    this.acceptedQuantity,
    required this.pricePerUnit,
    GeoLocation? pickupLocation,
    String? pickupCounty,
    String? pickupSubCounty,
    String? pickupArea,
    this.status = ContributionStatus.committed,
    required this.createdAt,
  }) : pickupLocation = pickupLocation ??
            GeoLocation(
              county: pickupCounty ?? '',
              subCounty: pickupSubCounty ?? '',
              area: pickupArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            );

  double get effectiveQuantity => acceptedQuantity ?? committedQuantity;

  double get subtotal => effectiveQuantity * pricePerUnit;

  String get pickupBroadLocation => pickupLocation.broadLocation;

  CommunityContributionModel copyWith({
    ContributionStatus? status,
    double? acceptedQuantity,
  }) =>
      CommunityContributionModel(
        id: id,
        preOrderId: preOrderId,
        farmerId: farmerId,
        farmerName: farmerName,
        committedQuantity: committedQuantity,
        acceptedQuantity: acceptedQuantity ?? this.acceptedQuantity,
        pricePerUnit: pricePerUnit,
        pickupLocation: pickupLocation,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
