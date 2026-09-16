class CounterOfferModel {
  final String id;
  final String offerId;
  final String byUserId;
  final String byName;
  final double pricePerUnit;
  final double quantity;
  final String? message;
  final DateTime createdAt;

  const CounterOfferModel({
    required this.id,
    required this.offerId,
    required this.byUserId,
    required this.byName,
    required this.pricePerUnit,
    required this.quantity,
    this.message,
    required this.createdAt,
  });
}
