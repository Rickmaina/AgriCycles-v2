import '../../core/constants/enums.dart';

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

  final String pickupCounty;
  final String pickupSubCounty;
  final String pickupArea;

  final ContributionStatus status;
  final DateTime createdAt;

  const CommunityContributionModel({
    required this.id,
    required this.preOrderId,
    required this.farmerId,
    required this.farmerName,
    required this.committedQuantity,
    this.acceptedQuantity,
    required this.pricePerUnit,
    required this.pickupCounty,
    required this.pickupSubCounty,
    required this.pickupArea,
    this.status = ContributionStatus.committed,
    required this.createdAt,
  });

  double get effectiveQuantity => acceptedQuantity ?? committedQuantity;

  double get subtotal => effectiveQuantity * pricePerUnit;

  String get pickupBroadLocation => '$pickupArea, $pickupSubCounty';

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
        pickupCounty: pickupCounty,
        pickupSubCounty: pickupSubCounty,
        pickupArea: pickupArea,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
