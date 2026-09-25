import '../../core/constants/enums.dart';
import 'geo_location.dart';

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

  final GeoLocation deliveryLocation;
  final String? deliveryNotes;

  final BuyRequestStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  BuyRequestModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.resourceType,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.offeredPricePerUnit,
    this.description,
    GeoLocation? deliveryLocation,
    String? deliveryCounty,
    String? deliverySubCounty,
    String? deliveryArea,
    this.deliveryNotes,
    this.status = BuyRequestStatus.open,
    required this.createdAt,
    this.expiresAt,
  }) : deliveryLocation = deliveryLocation ??
            GeoLocation(
              county: deliveryCounty ?? '',
              subCounty: deliverySubCounty ?? '',
              area: deliveryArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            );

  double get totalBudget => quantity * offeredPricePerUnit;

  String get deliveryBroadLocation => deliveryLocation.broadLocation;

  String get deliveryCounty => deliveryLocation.county;
  String get deliverySubCounty => deliveryLocation.subCounty;
  String get deliveryArea => deliveryLocation.area;

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
        deliveryLocation: deliveryLocation,
        deliveryNotes: deliveryNotes,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}
