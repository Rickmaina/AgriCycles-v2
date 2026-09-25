import '../../core/constants/enums.dart';
import 'geo_location.dart';

class OfferModel {
  final String id;
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final double quantity;
  final double pricePerUnit;
  final String? message;
  final GeoLocation deliveryLocation;
  final String? deliveryNotes;
  final OfferStatus status;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.quantity,
    required this.pricePerUnit,
    this.message,
    GeoLocation? deliveryLocation,
    String? deliveryCounty,
    String? deliverySubCounty,
    String? deliveryArea,
    this.deliveryNotes,
    this.status = OfferStatus.pending,
    required this.createdAt,
  }) : deliveryLocation = deliveryLocation ??
            GeoLocation(
              county: deliveryCounty ?? '',
              subCounty: deliverySubCounty ?? '',
              area: deliveryArea ?? '',
              lat: null,
              lng: null,
              source: LocationSource.selfReported,
            );

  String get deliveryBroadLocation => deliveryLocation.broadLocation;
  String get deliveryCounty => deliveryLocation.county;
  String get deliverySubCounty => deliveryLocation.subCounty;
  String get deliveryArea => deliveryLocation.area;

  OfferModel copyWith({OfferStatus? status}) => OfferModel(
        id: id,
        listingId: listingId,
        sellerId: sellerId,
        sellerName: sellerName,
        buyerId: buyerId,
        buyerName: buyerName,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        message: message,
        deliveryLocation: deliveryLocation,
        deliveryNotes: deliveryNotes,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
