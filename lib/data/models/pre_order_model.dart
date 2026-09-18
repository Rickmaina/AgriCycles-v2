import '../../core/constants/enums.dart';

/// A buyer-defined aggregate order. Farmers commit quantities until
/// the target is met, then it locks and moves through the standard
/// order pipeline as one aggregated procurement.
class PreOrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final bool buyerIsCompany;

  final String resourceType;
  final String category;
  final double targetQuantity;
  final String unit;
  final double offeredPricePerUnit;
  final String? description;

  final String deliveryCounty;
  final String deliverySubCounty;
  final String deliveryArea;
  final String? deliveryNotes;

  final DateTime deadline;
  final DateTime createdAt;
  final PreOrderStatus status;

  const PreOrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerIsCompany,
    required this.resourceType,
    required this.category,
    required this.targetQuantity,
    required this.unit,
    required this.offeredPricePerUnit,
    this.description,
    required this.deliveryCounty,
    required this.deliverySubCounty,
    required this.deliveryArea,
    this.deliveryNotes,
    required this.deadline,
    required this.createdAt,
    this.status = PreOrderStatus.open,
  });

  double get totalBudget => targetQuantity * offeredPricePerUnit;

  String get deliveryBroadLocation => '$deliveryArea, $deliverySubCounty';

  PreOrderModel copyWith({PreOrderStatus? status}) => PreOrderModel(
        id: id,
        buyerId: buyerId,
        buyerName: buyerName,
        buyerIsCompany: buyerIsCompany,
        resourceType: resourceType,
        category: category,
        targetQuantity: targetQuantity,
        unit: unit,
        offeredPricePerUnit: offeredPricePerUnit,
        description: description,
        deliveryCounty: deliveryCounty,
        deliverySubCounty: deliverySubCounty,
        deliveryArea: deliveryArea,
        deliveryNotes: deliveryNotes,
        deadline: deadline,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
