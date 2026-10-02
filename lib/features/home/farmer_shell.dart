import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../../shared/widgets/farmer_drawer.dart';

class FarmerShell extends ConsumerWidget {
  final Widget child;

  const FarmerShell({
    super.key,
    required this.child,
  });

  static const _tabs = <String>[
    AppRoutes.home,
    AppRoutes.market,
    AppRoutes.activity,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final isMainTab = _tabs.contains(location);
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        leading: isMainTab
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
        title: Text(
          _titleFor(location, user?.name ?? ''),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (user != null)
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(
                  myUnreadCountProvider(user.id),
                );

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      tooltip: 'Notifications',
                      onPressed: () {
                        context.push(AppRoutes.notifications);
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
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
        ],
      ),
      drawer: isMainTab ? const FarmerDrawer() : null,
      body: child,
      bottomNavigationBar: isMainTab
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(_tabs[index]);
              },
              backgroundColor: theme.surface,
              indicatorColor: theme.primaryMuted,
              destinations: [
                _navDestination(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  selected: selectedIndex == 0,
                  badgeCount: 0,
                ),
                _navDestination(
                  label: 'Market',
                  icon: Icons.storefront_outlined,
                  selectedIcon: Icons.storefront,
                  selected: selectedIndex == 1,
                  badgeCount: 0,
                ),
                _navDestination(
                  label: 'Activity',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  selected: selectedIndex == 2,
                  badgeCount: 0,
                ),
                _navDestination(
                  label: 'Profile',
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  selected: selectedIndex == 3,
                  badgeCount: user == null
                      ? 0
                      : ref.watch(myUnreadCountProvider(user.id)),
                ),
              ],
            )
          : null,
    );
  }

  NavigationDestination _navDestination({
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool selected,
    required int badgeCount,
  }) {
    return NavigationDestination(
      icon: _BadgeIcon(
        icon: icon,
        selected: selected,
        badgeCount: badgeCount,
      ),
      selectedIcon: _BadgeIcon(
        icon: selectedIcon,
        selected: true,
        badgeCount: badgeCount,
      ),
      label: label,
    );
  }

  int _selectedIndex(String location) {
    if (location == AppRoutes.market) return 1;
    if (location == AppRoutes.activity) return 2;
    if (location == AppRoutes.profile) return 3;
    return 0;
  }

  String _titleFor(String location, String name) {
    if (location == AppRoutes.home) {
      return 'Home';
    }

    if (location == AppRoutes.market) {
      return 'Market';
    }

    if (location == AppRoutes.activity) {
      return 'My activity';
    }

    if (location == AppRoutes.notifications) {
      return 'Notifications';
    }

    if (location == AppRoutes.help) {
      return 'Help';
    }

    if (location == AppRoutes.postNeed) {
      return 'Post a need';
    }

    if (location == AppRoutes.makeOffer) {
      return 'Make an offer';
    }

    if (location == AppRoutes.profile) {
      return 'My profile';
    }

    if (location == AppRoutes.browse) {
      return 'Marketplace';
    }

    if (location == AppRoutes.createListing) {
      return 'Sell';
    }

    if (location == AppRoutes.myListings) {
      return 'My listings';
    }

    if (location == AppRoutes.incomingOffers) {
      return 'Offers';
    }

    if (location == AppRoutes.orders) {
      return 'My orders';
    }

    if (location == AppRoutes.browseNeeds) {
      return 'Looking for';
    }

    if (location == AppRoutes.communityOrders) {
      return 'Community orders';
    }

    return 'AgriCycles';
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.selected,
    required this.badgeCount,
  });

  final IconData icon;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2E7D32) : const Color(0xFF546E4F);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
