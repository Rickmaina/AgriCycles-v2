import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../admin/logistics_queue_screen.dart';
import '../admin/verification_queue_screen.dart';
import '../marketplace/browse_screen.dart';
import '../marketplace/create_listing_screen.dart';
import '../orders/orders_list_screen.dart';
import '../profile/profile_screen.dart';
import 'farmer_dashboard.dart';
import 'widgets/company_home.dart';
import 'widgets/admin_home.dart';
import 'widgets/farmer_market_tab.dart';

/// The single app shell. Role-aware bottom nav (Section 4.1).
/// Every role lands here after login/onboarding; only the tab bodies
/// and nav items differ.
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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.login);
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

  /// FAB only on the farmer's Market tab (they're the sellers).
  Widget? _fabFor(UserRole role, int index) {
    if (role != UserRole.farmer || index != 1) return null;
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateListingScreen()),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Sell'),
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
            return const BrowseScreen();
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
