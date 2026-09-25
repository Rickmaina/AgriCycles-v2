import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../admin/logistics_queue_screen.dart';
import '../admin/pending_review_queue_screen.dart';
import '../admin/verification_queue_screen.dart';
import '../disputes/screens/admin_disputes_screen.dart';
import '../marketplace/company_browse_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../orders/cockpit_orders_list_screen.dart';
import '../profile/cockpit_profile_screen.dart';
import 'widgets/admin_home.dart';
import 'widgets/company_home.dart';

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

    final isFarmer = user.role == UserRole.farmer;
    final navItems = isFarmer ? const <_NavItem>[] : _navItemsFor(user.role);
    if (_index >= navItems.length) _index = 0;

    final roleTheme = RoleTheme.of(user.role);

    return Scaffold(
      key: ValueKey('shell-${user.role.name}'),
      drawer: isFarmer ? const FarmerDrawer() : null,
      appBar: _buildAppBar(user.name, roleTheme, isFarmer),
      body: _bodyFor(user.role, isFarmer ? 0 : _index),
      bottomNavigationBar: isFarmer || navItems.length <= 1
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _index,
              selectedItemColor: roleTheme.primary,
              unselectedItemColor: roleTheme.textMuted,
              backgroundColor: roleTheme.surface,
              onTap: (i) => setState(() => _index = i),
              items: navItems
                  .map((n) => BottomNavigationBarItem(
                        icon: Icon(n.icon),
                        activeIcon:
                            Icon(n.activeIcon, color: roleTheme.primary),
                        label: n.label,
                      ))
                  .toList(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String name,
    RoleTheme roleTheme,
    bool isFarmer,
  ) {
    final user = ref.watch(authProvider);
    return AppBar(
      backgroundColor: roleTheme.appBarBackground,
      foregroundColor: roleTheme.appBarForeground,
      elevation: 0,
      leading: isFarmer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Text(
        'Hi, ${name.split(" ").first}',
        style: TextStyle(
          color: roleTheme.appBarForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: roleTheme.appBarForeground),
      actions: [
        if (user != null)
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
                        constraints: const BoxConstraints(minWidth: 16),
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
        if (!isFarmer)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.login);
            },
          ),
      ],
    );
  }

  Widget _bodyFor(UserRole role, int index) {
    if (role == UserRole.farmer) {
      return const FarmerDashboard();
    }

    switch (role) {
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
            return const PendingReviewQueueScreen();
          case 3:
            return const LogisticsQueueScreen();
          case 4:
            return const AdminDisputesScreen();
          case 5:
            return const ProfileScreen();
        }
      case UserRole.farmer:
      case UserRole.vet:
        break;
    }
    return const SizedBox.shrink();
  }

  List<_NavItem> _navItemsFor(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const [];
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
          _NavItem(Icons.verified_user_outlined, Icons.verified_user,
              'Verify'),
          _NavItem(Icons.fact_check_outlined, Icons.fact_check, 'Review'),
          _NavItem(Icons.local_shipping_outlined, Icons.local_shipping,
              'Logistics'),
          _NavItem(Icons.gavel_outlined, Icons.gavel, 'Disputes'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      case UserRole.vet:
        return const [];
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
