import '../../core/constants/enums.dart';

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
  final String deliveryCounty;
  final String deliverySubCounty;
  final String deliveryArea;
  final String? deliveryNotes;
  final OfferStatus status;
  final DateTime createdAt;

  const OfferModel({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.quantity,
    required this.pricePerUnit,
    this.message,
    required this.deliveryCounty,
    required this.deliverySubCounty,
    required this.deliveryArea,
    this.deliveryNotes,
    this.status = OfferStatus.pending,
    required this.createdAt,
  });

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
        deliveryCounty: deliveryCounty,
        deliverySubCounty: deliverySubCounty,
        deliveryArea: deliveryArea,
        deliveryNotes: deliveryNotes,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
