import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../features/help/help_screen.dart';
import '../../features/marketplace/screens/browse_screen.dart';
import '../../features/marketplace/screens/my_listings_screen.dart';
import '../../features/marketplace/screens/create_listing_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/orders_list_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/buy_requests/screens/post_need_screen.dart';
import '../../features/buy_requests/screens/browse_needs_screen.dart';
import '../../features/community/screens/community_orders_list_screen.dart';

/// WhatsApp-style left drawer for farmer role.
///
/// Every destination the farmer needs, one tap away. Farmer-only —
/// company and admin keep their bottom nav.
class FarmerDrawer extends ConsumerWidget {
  const FarmerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);

    return Drawer(
      backgroundColor: theme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              name: user?.name ?? 'Farmer',
              subtitle: _locationLine(user?.area, user?.county),
              theme: theme,
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    theme: theme,
                    onTap: () => _popAndClose(context),
                  ),
                  _DrawerItem(
                    icon: Icons.sell_outlined,
                    label: 'Sell something',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const CreateListingScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_basket_outlined,
                    label: 'Buy something',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const BrowseScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.list_alt_outlined,
                    label: 'My Activity',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const OrdersListScreen(),
                    ),
                  ),
                  const _SectionDivider(),
                  _DrawerItem(
                    icon: Icons.campaign_outlined,
                    label: 'Looking for',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const BrowseNeedsScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.add_circle_outline,
                    label: 'Post what I need',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const PostNeedScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.groups_outlined,
                    label: 'Community orders',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const CommunityOrdersListScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'My listings',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const MyListingsScreen(),
                    ),
                  ),
                  const _SectionDivider(),
                  _DrawerItem(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const NotificationsScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const ProfileScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help',
                    theme: theme,
                    onTap: () => _pushAndClose(
                      context,
                      const HelpScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    theme: theme,
                    enabled: false,
                    onTap: () {},
                  ),
                  const _SectionDivider(),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Log out',
                    theme: theme,
                    destructive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(authProvider.notifier).logout();
                      context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _popAndClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _pushAndClose(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _locationLine(String? area, String? county) {
    final parts = [area, county].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Farmer' : parts.join(', ');
  }
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final RoleTheme theme;

  const _DrawerHeader({
    required this.name,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: theme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final RoleTheme theme;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? theme.textMuted.withValues(alpha: 0.5)
        : destructive
            ? theme.danger
            : theme.textPrimary;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: enabled
                  ? (destructive ? theme.danger : theme.primary)
                  : theme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}
