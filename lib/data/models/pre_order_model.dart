import '../../core/constants/enums.dart';
import 'geo_location.dart';

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

  final GeoLocation deliveryLocation;
  final String? deliveryNotes;

  final DateTime deadline;
  final DateTime createdAt;
  final PreOrderStatus status;

  PreOrderModel({
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
    GeoLocation? deliveryLocation,
    String? deliveryCounty,
    String? deliverySubCounty,
    String? deliveryArea,
    this.deliveryNotes,
    required this.deadline,
    required this.createdAt,
    this.status = PreOrderStatus.open,
  }) : deliveryLocation = deliveryLocation ??
            GeoLocation(
              county: deliveryCounty ?? '',
              subCounty: deliverySubCounty ?? '',
              area: deliveryArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            );

  double get totalBudget => targetQuantity * offeredPricePerUnit;

  String get deliveryBroadLocation => deliveryLocation.broadLocation;

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
        deliveryLocation: deliveryLocation,
        deliveryNotes: deliveryNotes,
        deadline: deadline,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
