import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/counter_offer_model.dart';
import '../models/listing_model.dart';
import '../models/offer_model.dart';
import '../../core/constants/enums.dart';
import 'mock/mock_listings.dart';

const int kMaxCounterRounds = 5;
const Duration kNegotiationTtl = Duration(days: 7);

class MarketplaceState {
  final List<ListingModel> listings;
  final List<OfferModel> offers;
  final List<CounterOfferModel> counterOffers;

  const MarketplaceState({
    required this.listings,
    required this.offers,
    required this.counterOffers,
  });

  MarketplaceState copyWith({
    List<ListingModel>? listings,
    List<OfferModel>? offers,
    List<CounterOfferModel>? counterOffers,
  }) =>
      MarketplaceState(
        listings: listings ?? this.listings,
        offers: offers ?? this.offers,
        counterOffers: counterOffers ?? this.counterOffers,
      );
}

class MarketplaceService extends StateNotifier<MarketplaceState> {
  MarketplaceService()
      : super(MarketplaceState(
          listings: List.of(MockListings.all),
          offers: const [],
          counterOffers: const [],
        ));

  void addListing(ListingModel listing) {
    state = state.copyWith(listings: [listing, ...state.listings]);
  }

  void removeListing(String id) {
    state = state.copyWith(
      listings: state.listings.where((l) => l.id != id).toList(),
    );
  }

  List<ListingModel> listingsFor(String sellerId) =>
      state.listings.where((l) => l.sellerId == sellerId).toList();

  ListingModel? listingById(String id) {
    for (final l in state.listings) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<OfferModel> offersForListing(String listingId) =>
      state.offers.where((o) => o.listingId == listingId).toList();

  List<OfferModel> offersByBuyer(String buyerId) =>
      state.offers.where((o) => o.buyerId == buyerId).toList();

  List<OfferModel> offersForSeller(String sellerId) {
    final myListingIds = listingsFor(sellerId).map((l) => l.id).toSet();
    return state.offers
        .where((o) => myListingIds.contains(o.listingId))
        .toList();
  }

  OfferModel? offerById(String id) {
    for (final o in state.offers) {
      if (o.id == id) return o;
    }
    return null;
  }

  OfferModel createOffer({
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
  }) {
    final offer = OfferModel(
      id: 'o${DateTime.now().millisecondsSinceEpoch}',
      listingId: listing.id,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: buyerId,
      buyerName: buyerName,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      message: message,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(offers: [offer, ...state.offers]);
    return offer;
  }

  void updateOfferStatus(String offerId, OfferStatus status) {
    state = state.copyWith(
      offers: state.offers
          .map((o) => o.id == offerId ? o.copyWith(status: status) : o)
          .toList(),
    );
  }

  List<CounterOfferModel> counterOffersFor(String offerId) {
    final list = state.counterOffers
        .where((c) => c.offerId == offerId)
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  CounterOfferModel? latestCounter(String offerId) {
    final list = counterOffersFor(offerId);
    return list.isEmpty ? null : list.last;
  }

  int counterRoundsUsed(String offerId) => counterOffersFor(offerId).length;

  bool isCounterCapped(String offerId) =>
      counterRoundsUsed(offerId) >= kMaxCounterRounds;

  bool isExpired(OfferModel offer) {
    final age = DateTime.now().difference(offer.createdAt);
    if (age <= kNegotiationTtl) return false;
    return offer.status == OfferStatus.pending ||
        offer.status == OfferStatus.countered;
  }

  CounterOfferModel addCounterOffer({
    required OfferModel offer,
    required String byUserId,
    required String byName,
    required double pricePerUnit,
    required double quantity,
    String? message,
  }) {
    final counter = CounterOfferModel(
      id: 'co${DateTime.now().millisecondsSinceEpoch}',
      offerId: offer.id,
      byUserId: byUserId,
      byName: byName,
      pricePerUnit: pricePerUnit,
      quantity: quantity,
      message: message,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      counterOffers: [...state.counterOffers, counter],
      offers: state.offers
          .map((o) => o.id == offer.id
              ? o.copyWith(status: OfferStatus.countered)
              : o)
          .toList(),
    );
    return counter;
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceService, MarketplaceState>(
  (ref) => MarketplaceService(),
);
