import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/listing_model.dart';
import '../models/offer_model.dart';
import 'mock/mock_listings.dart';

class MarketplaceState {
  final List<ListingModel> listings;
  final List<OfferModel> offers;

  const MarketplaceState({required this.listings, required this.offers});

  MarketplaceState copyWith({
    List<ListingModel>? listings,
    List<OfferModel>? offers,
  }) =>
      MarketplaceState(
        listings: listings ?? this.listings,
        offers: offers ?? this.offers,
      );
}

class MarketplaceService extends StateNotifier<MarketplaceState> {
  MarketplaceService()
      : super(MarketplaceState(
          listings: List.of(MockListings.all),
          offers: const [],
        ));

  // ── Listings ──────────────────────────────────────────────────

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

  // ── Offers ────────────────────────────────────────────────────

  List<OfferModel> offersForListing(String listingId) =>
      state.offers.where((o) => o.listingId == listingId).toList();

  List<OfferModel> offersByBuyer(String buyerId) =>
      state.offers.where((o) => o.buyerId == buyerId).toList();

  List<OfferModel> offersForSeller(String sellerId) {
    final myListingIds =
        listingsFor(sellerId).map((l) => l.id).toSet();
    return state.offers
        .where((o) => myListingIds.contains(o.listingId))
        .toList();
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
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceService, MarketplaceState>(
  (ref) => MarketplaceService(),
);
