import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/marketplace_service.dart';

/// Reads / writes to [MarketplaceService]. Screens read listings and
/// offers via the derived providers below; they never reach into
/// [marketplaceProvider] directly.
class MarketplaceController {
  MarketplaceController(this._ref);
  final Ref _ref;

  MarketplaceService get _svc =>
      _ref.read(marketplaceProvider.notifier);

  // ── Listings ──────────────────────────────────────────────────

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

  // ── Offers ────────────────────────────────────────────────────

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
  }) {
    return _svc.createOffer(
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
  }

  void updateOfferStatus(String offerId, OfferStatus status) =>
      _svc.updateOfferStatus(offerId, status);
}

final marketplaceControllerProvider =
    Provider<MarketplaceController>((ref) => MarketplaceController(ref));

// ── Derived providers ─────────────────────────────────────────────
// Screens watch these directly. They only rebuild when the underlying
// data changes.

/// All listings (unfiltered).
final allListingsProvider = Provider<List<ListingModel>>(
  (ref) => ref.watch(marketplaceProvider).listings,
);

/// Listings by a given seller.
final myListingsProvider = Provider.family<List<ListingModel>, String>(
  (ref, sellerId) => ref
      .watch(marketplaceProvider)
      .listings
      .where((l) => l.sellerId == sellerId)
      .toList(),
);

/// Offers on listings owned by a given seller.
final incomingOffersProvider =
    Provider.family<List<OfferModel>, String>((ref, sellerId) {
  final state = ref.watch(marketplaceProvider);
  final myListingIds =
      state.listings.where((l) => l.sellerId == sellerId).map((l) => l.id).toSet();
  return state.offers.where((o) => myListingIds.contains(o.listingId)).toList();
});
