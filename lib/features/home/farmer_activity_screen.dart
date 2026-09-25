import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_tile.dart';
import '../marketplace/controllers/marketplace_controller.dart';

/// Choice screen: offers, orders, listings.
class FarmerActivityScreen extends ConsumerWidget {
  const FarmerActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final offers = user == null
        ? <OfferModel>[]
        : ref
            .watch(incomingOffersProvider(user.id))
            .where((o) =>
                o.status == OfferStatus.pending ||
                o.status == OfferStatus.countered)
            .toList();

    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FarmerTile(
            icon: Icons.handshake_outlined,
            title: 'Offers',
            subtitle: 'Prices people sent you',
            badge: offers.isEmpty ? null : '${offers.length}',
            onTap: () => context.go(AppRoutes.incomingOffers),
          ),
          const SizedBox(height: 14),
          FarmerTile(
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            subtitle: 'Buying and selling',
            onTap: () => context.go(AppRoutes.orders),
          ),
          const SizedBox(height: 14),
          FarmerTile(
            icon: Icons.inventory_2_outlined,
            title: 'My listings',
            subtitle: 'What you are selling',
            onTap: () => context.go(AppRoutes.myListings),
          ),
        ],
      ),
    );
  }
}
