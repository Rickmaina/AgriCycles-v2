import '../../core/constants/enums.dart';
import 'geo_location.dart';

/// A seller's response to a buy request. Includes the seller's asking
/// price and their own pickup point + estimated transport cost so the
/// buyer can compare landed cost, not just unit price.
class BuyRequestOfferModel {
  final String id;
  final String buyRequestId;
  final String sellerId;
  final String sellerName;

  final double pricePerUnit;
  final double quantity; // how much of the request this seller can supply
  final String? message;

  final GeoLocation pickupLocation;

  final double estimatedTransportCost;

  final BuyRequestOfferStatus status;
  final DateTime createdAt;

  BuyRequestOfferModel({
    required this.id,
    required this.buyRequestId,
    required this.sellerId,
    required this.sellerName,
    required this.pricePerUnit,
    required this.quantity,
    this.message,
    GeoLocation? pickupLocation,
    String? pickupCounty,
    String? pickupSubCounty,
    String? pickupArea,
    required this.estimatedTransportCost,
    this.status = BuyRequestOfferStatus.pending,
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

  /// Cost of goods alone.
  double get subtotal => pricePerUnit * quantity;

  /// Total the buyer pays: goods + transport.
  double get landedCost => subtotal + estimatedTransportCost;

  String get pickupBroadLocation => pickupLocation.broadLocation;

  BuyRequestOfferModel copyWith({BuyRequestOfferStatus? status}) =>
      BuyRequestOfferModel(
        id: id,
        buyRequestId: buyRequestId,
        sellerId: sellerId,
        sellerName: sellerName,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        message: message,
        pickupLocation: pickupLocation,
        estimatedTransportCost: estimatedTransportCost,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
