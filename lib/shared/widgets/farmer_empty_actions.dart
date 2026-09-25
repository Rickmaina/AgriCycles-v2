import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import 'farmer_tile.dart';

/// Empty-state pattern for farmer screens: three jobs, not "nothing here".
class FarmerEmptyActions extends StatelessWidget {
  final String? header;

  const FarmerEmptyActions({super.key, this.header});

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              header!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ],
        FarmerTile(
          icon: Icons.sell_outlined,
          title: 'Sell something',
          subtitle: 'List what you have',
          onTap: () => context.go(AppRoutes.createListing),
        ),
        const SizedBox(height: 14),
        FarmerTile(
          icon: Icons.shopping_basket_outlined,
          title: 'Buy something',
          subtitle: 'Find what you need',
          onTap: () => context.go(AppRoutes.market),
        ),
        const SizedBox(height: 14),
        FarmerTile(
          icon: Icons.campaign_outlined,
          title: 'Ask for something',
          subtitle: 'Post what you need',
          onTap: () => context.go(AppRoutes.postNeed),
        ),
      ],
    );
  }
}
