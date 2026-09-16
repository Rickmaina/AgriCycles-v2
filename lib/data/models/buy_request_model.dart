import '../../core/constants/enums.dart';

/// A demand-first request: a buyer states what they need and what they
/// will pay. Sellers respond with individual offers. If the request
/// exceeds the community threshold, it becomes a community order
/// instead (see Section 16.2).
class BuyRequestModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String resourceType;
  final String category;
  final double quantity;
  final String unit;
  final double offeredPricePerUnit;
  final String? description;

  final String deliveryCounty;
  final String deliverySubCounty;
  final String deliveryArea;
  final String? deliveryNotes;

  final BuyRequestStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const BuyRequestModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.resourceType,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.offeredPricePerUnit,
    this.description,
    required this.deliveryCounty,
    required this.deliverySubCounty,
    required this.deliveryArea,
    this.deliveryNotes,
    this.status = BuyRequestStatus.open,
    required this.createdAt,
    this.expiresAt,
  });

  double get totalBudget => quantity * offeredPricePerUnit;

  String get deliveryBroadLocation =>
      '$deliveryArea, $deliverySubCounty';

  BuyRequestModel copyWith({BuyRequestStatus? status}) => BuyRequestModel(
        id: id,
        buyerId: buyerId,
        buyerName: buyerName,
        resourceType: resourceType,
        category: category,
        quantity: quantity,
        unit: unit,
        offeredPricePerUnit: offeredPricePerUnit,
        description: description,
        deliveryCounty: deliveryCounty,
        deliverySubCounty: deliverySubCounty,
        deliveryArea: deliveryArea,
        deliveryNotes: deliveryNotes,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}
