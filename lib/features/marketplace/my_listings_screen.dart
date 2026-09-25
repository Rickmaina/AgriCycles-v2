import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_status_icon.dart';
import '../../shared/widgets/farmer_tile.dart';
import 'controllers/marketplace_controller.dart';

/// Farmer's own listings. One row per listing, status as an icon.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final listings = ref.watch(myListingsProvider(user.id));

    if (listings.isEmpty) {
      return Container(
        color: theme.background,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                child: Text(
                  'You have nothing listed yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              FarmerTile(
                icon: Icons.sell_outlined,
                title: 'List something',
                subtitle: 'Sell what you have',
                onTap: () => context.go(AppRoutes.createListing),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: theme.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ListingRow(listing: listings[i]),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  final ListingModel listing;
  const _ListingRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final tone = farmerToneForListing(listing.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Row(
        children: [
          FarmerStatusIcon(tone: tone, size: FarmerStatusSize.large),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.resourceType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _detailLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _detailLine() {
    final price = listing.pricePerUnit.round();
    return 'KES $price / ${listing.unit}  ·  ${listing.county}';
  }
}
