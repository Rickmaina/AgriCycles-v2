import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/counter_offer_model.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/marketplace_service.dart';

class MarketplaceController {
  MarketplaceController(this._ref);
  final Ref _ref;

  MarketplaceService get _svc => _ref.read(marketplaceProvider.notifier);

  ListingModel addListing({
    required String sellerId,
    required String sellerName,
    required String resourceType,
    required String category,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    String? description,
    required String county,
    required String subCounty,
    required String area,
    required VerificationStatus sellerVerification,
  }) {
    final listing = ListingModel(
      id: 'l${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      sellerName: sellerName,
      resourceType: resourceType,
      category: category,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      description: description,
      county: county,
      subCounty: subCounty,
      area: area,
      sellerVerification: sellerVerification,
    );
    _svc.addListing(listing);
    return listing;
  }

  void removeListing(String listingId) => _svc.removeListing(listingId);

  OfferModel makeOffer({
    required ListingModel listing,
    required String buyerId,
    required String buyerName,
    required double quantity,
    required double pricePerUnit,
    required String deliveryCounty,
    required String deliverySubCounty,
    required String deliveryArea,
    String? deliveryNotes,
    String? message,
  }) =>
      _svc.createOffer(
        listing: listing,
        buyerId: buyerId,
        buyerName: buyerName,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        deliveryCounty: deliveryCounty,
        deliverySubCounty: deliverySubCounty,
        deliveryArea: deliveryArea,
        deliveryNotes: deliveryNotes,
        message: message,
      );

  void updateOfferStatus(String offerId, OfferStatus status) =>
      _svc.updateOfferStatus(offerId, status);

  bool isNegotiationClosed(OfferModel offer) =>
      _svc.isCounterCapped(offer.id) || _svc.isExpired(offer);

  String nextActorId(OfferModel offer) {
    final latest = _svc.latestCounter(offer.id);
    if (latest == null) return offer.sellerId;
    return latest.byUserId == offer.buyerId
        ? offer.sellerId
        : offer.buyerId;
  }

  bool canActorCounter({
    required OfferModel offer,
    required String actorId,
  }) {
    if (isNegotiationClosed(offer)) return false;
    if (offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.declined) {
      return false;
    }
    return nextActorId(offer) == actorId;
  }

  CounterOfferModel counterOffer({
    required OfferModel offer,
    required String byUserId,
    required String byName,
    required double pricePerUnit,
    required double quantity,
    String? message,
  }) =>
      _svc.addCounterOffer(
        offer: offer,
        byUserId: byUserId,
        byName: byName,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        message: message,
      );

  void acceptCurrent(OfferModel offer) =>
      _svc.updateOfferStatus(offer.id, OfferStatus.accepted);
}

final marketplaceControllerProvider =
    Provider<MarketplaceController>((ref) => MarketplaceController(ref));

final allListingsProvider = Provider<List<ListingModel>>(
  (ref) => ref.watch(marketplaceProvider).listings,
);

final myListingsProvider = Provider.family<List<ListingModel>, String>(
  (ref, sellerId) => ref
      .watch(marketplaceProvider)
      .listings
      .where((l) => l.sellerId == sellerId)
      .toList(),
);

final incomingOffersProvider =
    Provider.family<List<OfferModel>, String>((ref, sellerId) {
  final state = ref.watch(marketplaceProvider);
  final myListingIds = state.listings
      .where((l) => l.sellerId == sellerId)
      .map((l) => l.id)
      .toSet();
  return state.offers
      .where((o) => myListingIds.contains(o.listingId))
      .toList();
});

final counterOffersForProvider =
    Provider.family<List<CounterOfferModel>, String>((ref, offerId) {
  final list = ref
      .watch(marketplaceProvider)
      .counterOffers
      .where((c) => c.offerId == offerId)
      .toList();
  list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return list;
});
