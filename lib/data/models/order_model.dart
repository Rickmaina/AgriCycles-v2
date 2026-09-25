import '../../core/constants/enums.dart';
import 'geo_location.dart';

class OrderModel {
  final String id;
  final String listingId;
  final String resourceType;
  final String unit;

  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;

  final double quantity;
  final double pricePerUnit;

  final OrderState state;
  final LogisticsState? logisticsState;

  final DateTime createdAt;
  final DateTime updatedAt;

  final GeoLocation pickupLocation;
  final GeoLocation deliveryLocation;
  final String? deliveryNotes;

  OrderModel({
    required this.id,
    required this.listingId,
    required this.resourceType,
    required this.unit,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.pricePerUnit,
    required this.state,
    this.logisticsState,
    required this.createdAt,
    required this.updatedAt,
    GeoLocation? pickupLocation,
    String? pickupCounty,
    String? pickupSubCounty,
    String? pickupArea,
    GeoLocation? deliveryLocation,
    String? deliveryCounty,
    String? deliverySubCounty,
    String? deliveryArea,
    this.deliveryNotes,
  })  : pickupLocation = pickupLocation ??
            GeoLocation(
              county: pickupCounty ?? '',
              subCounty: pickupSubCounty ?? '',
              area: pickupArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            ),
        deliveryLocation = deliveryLocation ??
            GeoLocation(
              county: deliveryCounty ?? '',
              subCounty: deliverySubCounty ?? '',
              area: deliveryArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            );

  String get pickupBroadLocation => pickupLocation.broadLocation;
  String get deliveryBroadLocation => deliveryLocation.broadLocation;

  String get pickupCounty => pickupLocation.county;
  String get pickupSubCounty => pickupLocation.subCounty;
  String get pickupArea => pickupLocation.area;
  String get deliveryCounty => deliveryLocation.county;
  String get deliverySubCounty => deliveryLocation.subCounty;
  String get deliveryArea => deliveryLocation.area;

  OrderModel copyWith({
    OrderState? state,
    LogisticsState? logisticsState,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id,
      listingId: listingId,
      resourceType: resourceType,
      unit: unit,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      state: state ?? this.state,
      logisticsState: logisticsState ?? this.logisticsState,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupCounty: pickupLocation.county,
      pickupSubCounty: pickupLocation.subCounty,
      pickupArea: pickupLocation.area,
      deliveryCounty: deliveryLocation.county,
      deliverySubCounty: deliveryLocation.subCounty,
      deliveryArea: deliveryLocation.area,
      deliveryNotes: deliveryNotes,
    );
  }
}
