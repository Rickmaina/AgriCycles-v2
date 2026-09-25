import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/enums.dart';

import '../models/buy_request_model.dart';
import '../models/buy_request_offer_model.dart';
import '../models/listing_model.dart';
import 'marketplace_service.dart';
import '../../domain/landed_cost_calculator.dart';

/// Community-order threshold: requests at or above this quantity are
/// routed to the community pre-order flow (Section 16.2). Single
/// constant so it can be made per-category later without touching
/// call sites.
const double kCommunityQuantityThreshold = 1.0; // tonnes

class BuyRequestState {
  final List<BuyRequestModel> requests;
  final List<BuyRequestOfferModel> offers;

  const BuyRequestState({required this.requests, required this.offers});

  BuyRequestState copyWith({
    List<BuyRequestModel>? requests,
    List<BuyRequestOfferModel>? offers,
  }) =>
      BuyRequestState(
        requests: requests ?? this.requests,
        offers: offers ?? this.offers,
      );
}

class BuyRequestService extends StateNotifier<BuyRequestState> {
  BuyRequestService(this._ref)
      : super(const BuyRequestState(requests: [], offers: []));

  final Ref _ref;

  /// True when the request should be handled as a community pre-order
  /// rather than a single-seller broadcast.
  bool isCommunityScale(double quantity) =>
      quantity >= kCommunityQuantityThreshold;

  void post(BuyRequestModel request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void close(String requestId) {
    state = state.copyWith(
      requests: state.requests
          .map((r) => r.id == requestId
              ? r.copyWith(status: BuyRequestStatus.closed)
              : r)
          .toList(),
    );
  }

  List<BuyRequestModel> openRequests() =>
      state.requests.where((r) => r.status == BuyRequestStatus.open).toList();

  List<BuyRequestModel> byBuyer(String buyerId) =>
      state.requests.where((r) => r.buyerId == buyerId).toList();

  BuyRequestModel? requestById(String id) {
    for (final r in state.requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  void submitOffer(BuyRequestOfferModel offer) {
    state = state.copyWith(offers: [offer, ...state.offers]);
  }

  /// Suggest open listings for a buy request, ranked by landed cost
  /// ascending. Uses the buy request's delivery location as reference.
  List<ListingModel> suggestedSellers(String buyRequestId) {
    final req = requestById(buyRequestId);
    if (req == null) return [];

    final marketplace = _ref.read(marketplaceProvider).listings;
    final candidates =
        marketplace.where((l) => l.category == req.category).toList();

    double landedFor(ListingModel l) {
      final estTransport = estimateTransportKesForOrder(
        pickup: l.location,
        delivery: req.deliveryLocation,
        quantity: req.quantity,
      );
      return landedCostPerUnit(
        pricePerUnit: l.pricePerUnit,
        quantity: l.quantity,
        estimatedTransportCost: estTransport,
      );
    }

    candidates.sort((a, b) => landedFor(a).compareTo(landedFor(b)));
    return candidates;
  }

  List<BuyRequestOfferModel> offersFor(String requestId) =>
      state.offers.where((o) => o.buyRequestId == requestId).toList();

  List<BuyRequestOfferModel> offersBySeller(String sellerId) =>
      state.offers.where((o) => o.sellerId == sellerId).toList();

  void updateOfferStatus(String offerId, BuyRequestOfferStatus status) {
    state = state.copyWith(
      offers: state.offers
          .map((o) => o.id == offerId ? o.copyWith(status: status) : o)
          .toList(),
    );
  }
}

final buyRequestProvider =
    StateNotifierProvider<BuyRequestService, BuyRequestState>(
  (ref) => BuyRequestService(ref),
);
