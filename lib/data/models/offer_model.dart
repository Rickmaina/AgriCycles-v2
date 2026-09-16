import '../../core/constants/enums.dart';

/// A buyer's bid against a listing. Carries the buyer's intended
/// delivery point so the resulting order inherits it once accepted.
class OfferModel {
  final String id;
  final String listingId;
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

  OfferModel copyWith({
    double? quantity,
    double? pricePerUnit,
    String? message,
    OfferStatus? status,
  }) {
    return OfferModel(
      id: id,
      listingId: listingId,
      buyerId: buyerId,
      buyerName: buyerName,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      message: message ?? this.message,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
