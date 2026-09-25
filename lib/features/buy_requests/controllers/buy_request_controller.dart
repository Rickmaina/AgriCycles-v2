import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/buy_request_model.dart';
import '../../../data/models/geo_location.dart';
import '../../../data/models/buy_request_offer_model.dart';
import '../../../data/services/buy_request_service.dart';
import '../../../domain/transport_estimator.dart';

class BuyRequestController {
  BuyRequestController(this._ref);
  final Ref _ref;

  BuyRequestService get _svc => _ref.read(buyRequestProvider.notifier);

  bool isCommunityScale(double quantity) => _svc.isCommunityScale(quantity);

  BuyRequestModel postRequest({
    required String buyerId,
    required String buyerName,
    required String resourceType,
    required String category,
    required double quantity,
    required String unit,
    required double offeredPricePerUnit,
    String? description,
    GeoLocation? deliveryLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliverySubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryArea,
    String? deliveryNotes,
  }) {
    final now = DateTime.now();
    final request = BuyRequestModel(
      id: 'br${now.millisecondsSinceEpoch}',
      buyerId: buyerId,
      buyerName: buyerName,
      resourceType: resourceType,
      category: category,
      quantity: quantity,
      unit: unit,
      offeredPricePerUnit: offeredPricePerUnit,
      description: description,
      deliveryLocation: deliveryLocation,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 14)),
    );
    _svc.post(request);
    return request;
  }

  void close(String requestId) => _svc.close(requestId);

  BuyRequestOfferModel submitOffer({
    required BuyRequestModel request,
    required String sellerId,
    required String sellerName,
    required double pricePerUnit,
    required double quantity,
    GeoLocation? pickupLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupSubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupArea,
    String? message,
  }) {
    double transport;
    if (pickupLocation != null &&
        request.deliveryLocation.hasCoordinates &&
        pickupLocation.hasCoordinates) {
      final d = TransportEstimator.distanceKmForLocations(
          pickupLocation, request.deliveryLocation);
      transport =
          (TransportEstimator.baseFeeKes + TransportEstimator.perKmKes * d) *
              (1 + (quantity / TransportEstimator.loadFactorDivisor));
    } else {
      transport = TransportEstimator.costKes(
        pickupCounty: pickupCounty ?? pickupLocation?.county ?? '',
        deliveryCounty: request.deliveryCounty,
        quantityTonnes: quantity,
      );
    }
    final offer = BuyRequestOfferModel(
      id: 'bro${DateTime.now().millisecondsSinceEpoch}',
      buyRequestId: request.id,
      sellerId: sellerId,
      sellerName: sellerName,
      pricePerUnit: pricePerUnit,
      quantity: quantity,
      message: message,
      pickupLocation: pickupLocation,
      pickupCounty: pickupCounty,
      pickupSubCounty: pickupSubCounty,
      pickupArea: pickupArea,
      estimatedTransportCost: transport,
      createdAt: DateTime.now(),
    );
    _svc.submitOffer(offer);
    return offer;
  }

  void acceptOffer(BuyRequestOfferModel offer) {
    _svc.updateOfferStatus(offer.id, BuyRequestOfferStatus.accepted);
    _svc.close(offer.buyRequestId);
  }

  void declineOffer(BuyRequestOfferModel offer) {
    _svc.updateOfferStatus(offer.id, BuyRequestOfferStatus.declined);
  }
}

final buyRequestControllerProvider =
    Provider<BuyRequestController>((ref) => BuyRequestController(ref));

final openBuyRequestsProvider = Provider<List<BuyRequestModel>>(
  (ref) => ref
      .watch(buyRequestProvider)
      .requests
      .where((r) => r.status == BuyRequestStatus.open)
      .toList(),
);

final myBuyRequestsProvider =
    Provider.family<List<BuyRequestModel>, String>((ref, buyerId) {
  return ref
      .watch(buyRequestProvider)
      .requests
      .where((r) => r.buyerId == buyerId)
      .toList();
});

final buyRequestByIdProvider =
    Provider.family<BuyRequestModel?, String>((ref, id) {
  for (final r in ref.watch(buyRequestProvider).requests) {
    if (r.id == id) return r;
  }
  return null;
});

final buyRequestOffersProvider =
    Provider.family<List<BuyRequestOfferModel>, String>((ref, requestId) {
  return ref
      .watch(buyRequestProvider)
      .offers
      .where((o) => o.buyRequestId == requestId)
      .toList();
});
