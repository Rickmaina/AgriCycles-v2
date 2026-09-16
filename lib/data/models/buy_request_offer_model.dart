import '../../core/constants/enums.dart';

/// A seller's response to a buy request. Includes the seller's asking
/// price and their own pickup point + estimated transport cost so the
/// buyer can compare landed cost, not just unit price.
class BuyRequestOfferModel {
  final String id;
  final String buyRequestId;
  final String sellerId;
  final String sellerName;

  final double pricePerUnit;
  final double quantity;       // how much of the request this seller can supply
  final String? message;

  final String pickupCounty;
  final String pickupSubCounty;
  final String pickupArea;

  final double estimatedTransportCost;

  final BuyRequestOfferStatus status;
  final DateTime createdAt;

  const BuyRequestOfferModel({
    required this.id,
    required this.buyRequestId,
    required this.sellerId,
    required this.sellerName,
    required this.pricePerUnit,
    required this.quantity,
    this.message,
    required this.pickupCounty,
    required this.pickupSubCounty,
    required this.pickupArea,
    required this.estimatedTransportCost,
    this.status = BuyRequestOfferStatus.pending,
    required this.createdAt,
  });

  /// Cost of goods alone.
  double get subtotal => pricePerUnit * quantity;

  /// Total the buyer pays: goods + transport.
  double get landedCost => subtotal + estimatedTransportCost;

  String get pickupBroadLocation => '$pickupArea, $pickupSubCounty';

  BuyRequestOfferModel copyWith({BuyRequestOfferStatus? status}) =>
      BuyRequestOfferModel(
        id: id,
        buyRequestId: buyRequestId,
        sellerId: sellerId,
        sellerName: sellerName,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        message: message,
        pickupCounty: pickupCounty,
        pickupSubCounty: pickupSubCounty,
        pickupArea: pickupArea,
        estimatedTransportCost: estimatedTransportCost,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
