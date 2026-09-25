import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../shared/widgets/farmer_tile.dart';

/// Farmer Market home. Three entries: Browse, Community orders,
/// Looking for. Replaces the tabbed market view.
class MarketHomeScreen extends ConsumerWidget {
  const MarketHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            FarmerTile(
              icon: Icons.storefront_outlined,
              title: 'Browse listings',
              subtitle: 'See what is for sale near you',
              onTap: () => context.go(AppRoutes.browse),
            ),
            const SizedBox(height: 14),
            FarmerTile(
              icon: Icons.groups_outlined,
              title: 'Community orders',
              subtitle: 'Join a group buy with other farmers',
              onTap: () => context.go(AppRoutes.communityOrders),
            ),
            const SizedBox(height: 14),
            FarmerTile(
              icon: Icons.campaign_outlined,
              title: 'Looking for',
              subtitle: 'See what other people need',
              onTap: () => context.go(AppRoutes.browseNeeds),
            ),
          ],
        ),
      ),
    );
  }
}
