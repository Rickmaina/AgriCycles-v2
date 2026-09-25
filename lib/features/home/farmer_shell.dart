import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';

/// Farmer chrome: back + one overflow list. No bottom nav, no drawer.
class FarmerShell extends ConsumerWidget {
  final Widget child;
  const FarmerShell({super.key, required this.child});

  static const _routeTitles = <String, String>{
    AppRoutes.home: '',
    AppRoutes.market: 'Buy',
    AppRoutes.browse: 'Buy',
    AppRoutes.myListings: 'My listings',
    AppRoutes.createListing: 'Sell',
    AppRoutes.activity: 'My activity',
    AppRoutes.incomingOffers: 'Offers',
    AppRoutes.orders: 'Orders',
    AppRoutes.profile: 'Profile',
    AppRoutes.notifications: 'Notifications',
    AppRoutes.help: 'Help',
    AppRoutes.browseNeeds: 'Ask for something',
    AppRoutes.postNeed: 'Ask for something',
    AppRoutes.communityOrders: 'Join with others',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final location = GoRouterState.of(context).matchedLocation;
    final isHome = location == AppRoutes.home;
    final title = _routeTitles[location] ?? _prefixTitle(location);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isHome
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => _back(context, location),
              ),
        title: title.isEmpty
            ? null
            : Text(
                title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _onMenu(context, ref, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'notifications', child: Text('Notifications')),
              PopupMenuItem(value: 'help', child: Text('Help')),
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: child,
    );
  }

  void _back(BuildContext context, String location) {
    if (location == AppRoutes.browse ||
        location == AppRoutes.communityOrders ||
        location == AppRoutes.browseNeeds ||
        location == AppRoutes.postNeed) {
      context.go(AppRoutes.market);
      return;
    }
    if (location == AppRoutes.incomingOffers ||
        location == AppRoutes.orders ||
        location == AppRoutes.myListings) {
      context.go(AppRoutes.activity);
      return;
    }
    context.go(AppRoutes.home);
  }

  void _onMenu(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'notifications':
        context.go(AppRoutes.notifications);
        break;
      case 'help':
        context.go(AppRoutes.help);
        break;
      case 'profile':
        context.go(AppRoutes.profile);
        break;
      case 'logout':
        ref.read(authProvider.notifier).logout();
        context.go(AppRoutes.login);
        break;
    }
  }

  String _prefixTitle(String location) {
    for (final entry in _routeTitles.entries) {
      if (location.startsWith(entry.key) && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return 'AgriCycles';
  }
}
