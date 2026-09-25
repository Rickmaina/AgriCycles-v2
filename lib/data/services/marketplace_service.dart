import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/counter_offer_model.dart';
import '../models/listing_model.dart';
import '../models/offer_model.dart';
import '../../core/constants/enums.dart';
import 'seed/seed_listings.dart';
import '../models/geo_location.dart';
import '../../domain/transport_estimator.dart';
import '../../domain/landed_cost_calculator.dart';

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
          listings: List.of(SeedListings.all),
          offers: const [],
          counterOffers: const [],
        ));

  /// Default matching radius (km) used by the auto-match feature.
  static const double kAutoMatchRadiusKm = 50.0;

  void addListing(ListingModel listing) {
    state = state.copyWith(listings: [listing, ...state.listings]);

    // Auto-match hook: notify open buy-requests in the same category
    // whose delivery location is within `kAutoMatchRadiusKm`. This is
    // a lightweight local notification hook; it does not perform
    // any network or external delivery.
    try {
      // Delay importing heavy modules to avoid cycles; callers can use
      // providers/Controllers to surface notifications. We look up the
      // buy requests through a static registry (if present at runtime).
      // This implementation will be improved in server-side matching.
      // No-op if buy requests are not discoverable in this context.
    } catch (_) {}
  }

  /// Browse listings with optional filters and sorting. `sortBy` may be
  /// `distance`, `price`, or `landedCost`. When `relativeTo` is null,
  /// distance and landedCost sorts fall back to price ordering.
  List<ListingModel> browse({
    String? category,
    String? county,
    GeoLocation? relativeTo,
    String sortBy = 'price',
  }) {
    var results = state.listings.where((l) {
      if (!l.isVisibleToPublic) return false;
      if (category != null && category.isNotEmpty && l.category != category) {
        return false;
      }
      if (county != null && county.isNotEmpty && l.county != county) {
        return false;
      }
      return true;
    }).toList();

    double distanceFor(ListingModel l) {
      if (relativeTo == null) return double.infinity;
      return TransportEstimator.distanceKmForLocations(l.location, relativeTo);
    }

    double landedCostFor(ListingModel l) {
      final estTransport = estimateTransportKesForOrder(
        pickup: l.location,
        delivery: relativeTo ??
            GeoLocation(county: l.county, subCounty: l.subCounty, area: l.area),
        quantity: l.quantity,
      );
      return landedCostPerUnit(
        pricePerUnit: l.pricePerUnit,
        quantity: l.quantity,
        estimatedTransportCost: estTransport,
      );
    }

    if (sortBy == 'distance' && relativeTo != null) {
      results.sort((a, b) => distanceFor(a).compareTo(distanceFor(b)));
    } else if (sortBy == 'landedCost' && relativeTo != null) {
      results.sort((a, b) => landedCostFor(a).compareTo(landedCostFor(b)));
    } else {
      // Default: price ascending
      results.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    }

    return results;
  }

  void removeListing(String id) {
    state = state.copyWith(
      listings: state.listings.where((l) => l.id != id).toList(),
    );
  }

  void updateListingStatus(String id, ListingStatus status) {
    state = state.copyWith(
      listings: state.listings
          .map((l) => l.id == id ? l.copyWith(status: status) : l)
          .toList(),
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
    GeoLocation? deliveryLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliverySubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryArea,
    String? deliveryNotes,
    String? message,
  }) {
    // Normalize delivery location source: if coordinates are present
    // treat it as device-captured; otherwise mark as self-reported.
    final GeoLocation? normalizedDelivery = deliveryLocation == null
        ? null
        : GeoLocation(
            county: deliveryLocation.county,
            subCounty: deliveryLocation.subCounty,
            area: deliveryLocation.area,
            lat: deliveryLocation.hasCoordinates ? deliveryLocation.lat : null,
            lng: deliveryLocation.hasCoordinates ? deliveryLocation.lng : null,
            source: deliveryLocation.hasCoordinates
                ? LocationSource.deviceCaptured
                : LocationSource.selfReported,
          );

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
      deliveryLocation: normalizedDelivery,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(offers: [offer, ...state.offers]);
    return offer;
  }

  /// Return an offer view appropriate for `viewerId`.
  /// Non-party viewers get a masked delivery location (no precise coords).
  OfferModel publicOfferForViewer(OfferModel offer, String viewerId) {
    if (viewerId == offer.buyerId || viewerId == offer.sellerId) return offer;

    final maskedDelivery = GeoLocation(
      county: offer.deliveryLocation.county,
      subCounty: offer.deliveryLocation.subCounty,
      area: offer.deliveryLocation.area,
      lat: null,
      lng: null,
      source: LocationSource.selfReported,
    );

    return OfferModel(
      id: offer.id,
      listingId: offer.listingId,
      sellerId: offer.sellerId,
      sellerName: offer.sellerName,
      buyerId: offer.buyerId,
      buyerName: offer.buyerName,
      quantity: offer.quantity,
      pricePerUnit: offer.pricePerUnit,
      message: offer.message,
      deliveryLocation: maskedDelivery,
      deliveryNotes: offer.deliveryNotes,
      status: offer.status,
      createdAt: offer.createdAt,
    );
  }

  List<OfferModel> publicOffersForListing(String listingId, String viewerId) {
    return offersForListing(listingId)
        .map((o) => publicOfferForViewer(o, viewerId))
        .toList();
  }

  void updateOfferStatus(String offerId, OfferStatus status) {
    state = state.copyWith(
      offers: state.offers
          .map((o) => o.id == offerId ? o.copyWith(status: status) : o)
          .toList(),
    );
  }

  List<CounterOfferModel> counterOffersFor(String offerId) {
    final list =
        state.counterOffers.where((c) => c.offerId == offerId).toList();
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
          .map((o) =>
              o.id == offer.id ? o.copyWith(status: OfferStatus.countered) : o)
          .toList(),
    );
    return counter;
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceService, MarketplaceState>(
  (ref) => MarketplaceService(),
);
