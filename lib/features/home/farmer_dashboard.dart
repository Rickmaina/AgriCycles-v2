import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_tile.dart';
import '../marketplace/controllers/marketplace_controller.dart';

/// Farmer home. Three tiles plus one dismissible action-needed line.
class FarmerDashboard extends ConsumerStatefulWidget {
  const FarmerDashboard({super.key});

  @override
  ConsumerState<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends ConsumerState<FarmerDashboard> {
  bool _actionLineDismissed = false;

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final action = user == null ? null : _actionNeeded(user.id);

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (action != null && !_actionLineDismissed)
              _ActionNeededLine(
                theme: theme,
                text: action.text,
                onTap: action.onTap,
                onDismiss: () => setState(() => _actionLineDismissed = true),
              ),
            FarmerTile(
              icon: Icons.sell_outlined,
              title: 'Sell',
              subtitle: 'List what you have',
              onTap: () => context.go(AppRoutes.createListing),
            ),
            const SizedBox(height: 14),
            FarmerTile(
              icon: Icons.shopping_basket_outlined,
              title: 'Buy',
              subtitle: 'Find what you need',
              onTap: () => context.go(AppRoutes.market),
            ),
            const SizedBox(height: 14),
            FarmerTile(
              icon: Icons.list_alt_outlined,
              title: 'My activity',
              subtitle: 'Offers, orders, listings',
              onTap: () => context.go(AppRoutes.activity),
            ),
          ],
        ),
      ),
    );
  }

  _NeededAction? _actionNeeded(String userId) {
    final offers = ref.watch(incomingOffersProvider(userId)).where((o) =>
        o.status == OfferStatus.pending || o.status == OfferStatus.countered);
    final count = offers.length;
    if (count > 0) {
      return _NeededAction(
        text: count == 1 ? '1 offer waiting' : '$count offers waiting',
        onTap: () => context.go(AppRoutes.incomingOffers),
      );
    }

    final listings = ref.watch(myListingsProvider(userId));
    ListingModel? rejected;
    for (final l in listings) {
      if (l.status == ListingStatus.rejected) {
        rejected = l;
        break;
      }
    }
    if (rejected != null) {
      return _NeededAction(
        text: 'Your ${rejected.resourceType} listing needs a fix',
        onTap: () => context.go(AppRoutes.myListings),
      );
    }
    return null;
  }
}

class _NeededAction {
  final String text;
  final VoidCallback onTap;
  const _NeededAction({required this.text, required this.onTap});
}

class _ActionNeededLine extends StatelessWidget {
  final RoleTheme theme;
  final String text;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ActionNeededLine({
    required this.theme,
    required this.text,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Hide',
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
