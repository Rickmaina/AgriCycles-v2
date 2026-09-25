import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/counter_offer_model.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/models/geo_location.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/buy_request_service.dart';
import '../../../data/services/marketplace_service.dart';
// transport estimator not needed here; matching uses BuyRequestService.suggestedSellers

class MarketplaceController {
  MarketplaceController(this._ref);
  final Ref _ref;

  static const bool kListingReviewGateEnabled = true;

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
      status: kListingReviewGateEnabled
          ? ListingStatus.pendingReview
          : ListingStatus.active,
    );
    _svc.addListing(listing);

    // Auto-match check: use BuyRequestService.suggestedSellers to find
    // buy-requests for which this listing is a good match, then notify
    // buyer and seller. Avoid duplicate notifications by checking
    // existing notifications for the same recipient + target.
    try {
      final buyReqSvc = _ref.read(buyRequestProvider.notifier);
      final notificationList = _ref.read(notificationProvider);
      final notifier = _ref.read(notificationProvider.notifier);

      final openReqs = buyReqSvc.openRequests();
      for (final req in openReqs) {
        if (req.category != listing.category) continue;

        final ranked = buyReqSvc.suggestedSellers(req.id);
        // If this listing appears among top 5 suggestions, consider it a match.
        final index = ranked.indexWhere((l) => l.id == listing.id);
        if (index == -1 || index > 4) continue;

        // Avoid duplicate notifications for the same recipient + listing
        final alreadyNotifiedSeller = notificationList.any((n) =>
            n.recipientId == listing.sellerId && n.targetId == listing.id);
        if (!alreadyNotifiedSeller) {
          notifier.push(NotificationModel(
            id: 'n${DateTime.now().microsecondsSinceEpoch}',
            recipientId: listing.sellerId,
            type: NotificationType.system,
            title: 'Potential match',
            body:
                'Your new listing may match buy request #${req.id.substring(2)}',
            target: NotificationTarget.listing,
            targetId: listing.id,
            createdAt: DateTime.now(),
          ));
        }

        final alreadyNotifiedBuyer = notificationList.any(
            (n) => n.recipientId == req.buyerId && n.targetId == listing.id);
        if (!alreadyNotifiedBuyer) {
          notifier.push(NotificationModel(
            id: 'n${DateTime.now().microsecondsSinceEpoch + 1}',
            recipientId: req.buyerId,
            type: NotificationType.system,
            title: 'Matching listing found',
            body: 'A new listing in ${listing.category} may match your request',
            target: NotificationTarget.listing,
            targetId: listing.id,
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (_) {}
    return listing;
  }

  void removeListing(String listingId) => _svc.removeListing(listingId);

  void updateListingStatus(String listingId, ListingStatus status) {
    _svc.updateListingStatus(listingId, status);
  }

  OfferModel makeOffer({
    required ListingModel listing,
    required String buyerId,
    required String buyerName,
    required double quantity,
    required double pricePerUnit,
    GeoLocation? deliveryLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliverySubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryArea,
    String? deliveryNotes,
    String? message,
  }) =>
      _svc.createOffer(
        listing: listing,
        buyerId: buyerId,
        buyerName: buyerName,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        deliveryLocation: deliveryLocation,
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
    return latest.byUserId == offer.buyerId ? offer.sellerId : offer.buyerId;
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

final pendingReviewListingsProvider = Provider<List<ListingModel>>((ref) {
  return ref
      .watch(marketplaceProvider)
      .listings
      .where((l) => l.status == ListingStatus.pendingReview)
      .toList();
});

final incomingOffersProvider =
    Provider.family<List<OfferModel>, String>((ref, sellerId) {
  final state = ref.watch(marketplaceProvider);
  final myListingIds = state.listings
      .where((l) => l.sellerId == sellerId)
      .map((l) => l.id)
      .toSet();
  return state.offers.where((o) => myListingIds.contains(o.listingId)).toList();
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
