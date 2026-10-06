import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/marketplace_service.dart';
import '../../shared/widgets/farmer_tile.dart';
import '../marketplace/controllers/marketplace_controller.dart';
import '../orders/controllers/orders_controller.dart';

/// Farmer's activity hub: offers, bids, orders, listings.
class FarmerActivityScreen extends ConsumerWidget {
  const FarmerActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    // Incoming offers (bids on my listings)
    final incoming = ref.watch(incomingOffersProvider(user.id));
    final activeIncoming = incoming
        .where((o) =>
            o.status == OfferStatus.pending ||
            o.status == OfferStatus.countered)
        .toList();

    // Outgoing bids (offers I made)
    final outgoing =
        ref.watch(marketplaceProvider).offers.where((o) {
      return o.buyerId == user.id &&
          (o.status == OfferStatus.pending ||
              o.status == OfferStatus.countered);
    }).toList();

    // Orders
    final buying = ref.watch(buyingOrdersProvider(user.id));
    final selling = ref.watch(sellingOrdersProvider(user.id));
    final openBuying = buying.where((o) => !o.state.isTerminal).toList();
    final openSelling = selling.where((o) => !o.state.isTerminal).toList();
    final openOrders = openBuying.length + openSelling.length;

    // Listings
    final listings = ref.watch(myListingsProvider(user.id));
    final pendingListings =
        listings.where((l) => l.status == ListingStatus.pendingReview).length;
    final activeListings =
        listings.where((l) => l.status == ListingStatus.active).length;

    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FarmerTile(
            icon: Icons.handshake_outlined,
            title: 'Offers',
            subtitle: _offersSubtitle(activeIncoming.length),
            badge: activeIncoming.isEmpty
                ? null
                : '${activeIncoming.length}',
            onTap: () => context.push(AppRoutes.incomingOffers),
          ),
          const SizedBox(height: 14),
          FarmerTile(
            icon: Icons.send_outlined,
            title: 'My bids',
            subtitle: outgoing.isEmpty
                ? 'Offers you sent to sellers'
                : _bidsSubtitle(outgoing),
            badge: outgoing.isEmpty ? null : '${outgoing.length}',
            onTap: () => context.push(AppRoutes.incomingOffers),
          ),
          const SizedBox(height: 14),
          FarmerTile(
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            subtitle: openOrders == 0
                ? 'Buying and selling'
                : _ordersSubtitle(openBuying.length, openSelling.length),
            badge: openOrders == 0 ? null : '$openOrders',
            onTap: () => context.push(AppRoutes.orders),
          ),
          const SizedBox(height: 14),
          FarmerTile(
            icon: Icons.inventory_2_outlined,
            title: 'My listings',
            subtitle: listings.isEmpty
                ? 'What you are selling'
                : _listingsSubtitle(pendingListings, activeListings),
            badge: listings.isEmpty ? null : '${listings.length}',
            onTap: () => context.push(AppRoutes.myListings),
          ),
        ],
      ),
    );
  }

  String _offersSubtitle(int count) {
    if (count == 0) return 'Prices people sent you';
    if (count == 1) return '1 offer waiting for you';
    return '$count offers waiting for you';
  }

  String _bidsSubtitle(List<OfferModel> outgoing) {
    final waiting =
        outgoing.where((o) => o.status == OfferStatus.pending).length;
    if (waiting == 0) return 'Awaiting seller response';
    if (waiting == 1) return '1 bid awaiting response';
    return '$waiting bids awaiting response';
  }

  String _ordersSubtitle(int buying, int selling) {
    final parts = <String>[];
    if (buying > 0) parts.add('$buying buying');
    if (selling > 0) parts.add('$selling selling');
    return parts.join(' · ');
  }

  String _listingsSubtitle(int pending, int active) {
    final parts = <String>[];
    if (pending > 0) parts.add('$pending pending');
    if (active > 0) parts.add('$active active');
    if (parts.isEmpty) return 'Nothing active';
    return parts.join(' · ');
  }
}
