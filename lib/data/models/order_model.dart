import '../../core/constants/enums.dart';

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

  // Pickup (where the goods are)
  final String pickupCounty;
  final String pickupSubCounty;
  final String pickupArea;

  // Delivery (where the buyer wants them)
  final String deliveryCounty;
  final String deliverySubCounty;
  final String deliveryArea;
  final String? deliveryNotes;

  const OrderModel({
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
    required this.pickupCounty,
    required this.pickupSubCounty,
    required this.pickupArea,
    required this.deliveryCounty,
    required this.deliverySubCounty,
    required this.deliveryArea,
    this.deliveryNotes,
  });

  String get pickupBroadLocation => '$pickupArea, $pickupSubCounty';
  String get deliveryBroadLocation => '$deliveryArea, $deliverySubCounty';

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
      pickupCounty: pickupCounty,
      pickupSubCounty: pickupSubCounty,
      pickupArea: pickupArea,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
    );
  }
}
