import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../admin/logistics_queue_screen.dart';
import '../admin/verification_queue_screen.dart';
import '../auth/controllers/auth_controller.dart';
import '../buy_requests/screens/post_need_screen.dart';
import '../community/screens/create_pre_order_screen.dart';
import '../disputes/screens/admin_disputes_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../../data/services/notification_service.dart';
import '../marketplace/create_listing_screen.dart';
import '../orders/orders_list_screen.dart';
import '../profile/profile_screen.dart';
import 'farmer_dashboard.dart';
import 'widgets/admin_home.dart';
import 'widgets/company_home.dart';
import 'widgets/farmer_market_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navItems = _navItemsFor(user.role);
    if (_index >= navItems.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(" ").first}'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(myUnreadCountProvider(user.id));
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        constraints:
                            const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      floatingActionButton: _fabFor(user.role, _index),
      body: _bodyFor(user.role, _index),
      bottomNavigationBar: navItems.length == 1
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _index,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              onTap: (i) => setState(() => _index = i),
              items: navItems
                  .map((n) => BottomNavigationBarItem(
                        icon: Icon(n.icon),
                        activeIcon:
                            Icon(n.activeIcon, color: AppColors.primary),
                        label: n.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget? _fabFor(UserRole role, int index) {
    if (role != UserRole.farmer || index != 1) return null;
    return FloatingActionButton.extended(
      onPressed: () => _showMarketActions(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Post'),
    );
  }

  void _showMarketActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_box_outlined,
                  color: AppColors.primary),
              title: const Text('Sell a resource'),
              subtitle: const Text('List crop waste, manure, feed'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateListingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined,
                  color: AppColors.primary),
              title: const Text('Post a need'),
              subtitle: const Text('Buy-first: state what you need'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PostNeedScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined,
                  color: AppColors.primary),
              title: const Text('Start community order'),
              subtitle: const Text('Aggregate across many farms'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatePreOrderScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(UserRole role, int index) {
    switch (role) {
      case UserRole.farmer:
        switch (index) {
          case 0:
            return const FarmerDashboard();
          case 1:
            return const FarmerMarketTab();
          case 2:
            return const OrdersListScreen();
          case 3:
            return const ProfileScreen();
        }
      case UserRole.company:
        switch (index) {
          case 0:
            return const CompanyHome();
          case 1:
            return const FarmerMarketTab();
          case 2:
            return const OrdersListScreen();
          case 3:
            return const ProfileScreen();
        }
      case UserRole.admin:
        switch (index) {
          case 0:
            return const AdminHome();
          case 1:
            return const VerificationQueueScreen();
          case 2:
            return const LogisticsQueueScreen();
          case 3:
            return const AdminDisputesScreen();
          case 4:
            return const ProfileScreen();
        }
      case UserRole.vet:
        return const _VetPlaceholder();
    }
    return const SizedBox.shrink();
  }

  List<_NavItem> _navItemsFor(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.storefront_outlined, Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      case UserRole.company:
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.storefront_outlined, Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      case UserRole.admin:
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.verified_user_outlined, Icons.verified_user, 'Verify'),
          _NavItem(Icons.local_shipping_outlined, Icons.local_shipping,
              'Logistics'),
          _NavItem(Icons.gavel_outlined, Icons.gavel, 'Disputes'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      case UserRole.vet:
        return const [
          _NavItem(Icons.info_outline, Icons.info, 'About'),
        ];
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _VetPlaceholder extends StatelessWidget {
  const _VetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Vet module ships in v3.\nUse a Farmer or Company account to trade.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
