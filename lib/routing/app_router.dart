import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../data/services/auth_service.dart';
import '../data/services/company_profile_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/buy_requests/screens/browse_needs_screen.dart';
import '../features/buy_requests/screens/post_need_screen.dart';
import '../features/community/screens/community_orders_list_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/farmer_activity_screen.dart';
import '../features/home/farmer_dashboard.dart';
import '../features/home/farmer_shell.dart';
import '../features/home/home_shell.dart';
import '../features/marketplace/screens/browse_screen.dart';
import '../features/marketplace/screens/create_listing_screen.dart';
import '../features/marketplace/screens/incoming_offers_screen.dart';
import '../features/marketplace/screens/market_home_screen.dart';
import '../features/marketplace/screens/my_listings_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/farm_location_screen.dart';
import '../features/onboarding/company_onboarding_screen.dart';
import '../features/onboarding/company_pending_verification_screen.dart';
import '../features/onboarding/get_started_screen.dart';
import '../features/onboarding/onboarding_complete_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/orders/orders_list_screen.dart';
import '../features/profile/profile_screen.dart';
import 'route_guards.dart';

final _authRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => notifier.value++);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final profile = ref.read(companyProfileProvider);
      return redirectFor(
        user: user,
        companyProfile: profile,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const GetStartedScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingLocation,
        builder: (_, __) => const FarmLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingComplete,
        builder: (_, __) => const OnboardingCompleteScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyOnboarding,
        builder: (_, __) => const CompanyOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyPending,
        builder: (_, __) => const CompanyPendingVerificationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => FarmerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const FarmerDashboard(),
          ),
          GoRoute(
            path: AppRoutes.market,
            builder: (_, __) => const MarketHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.browse,
            builder: (_, __) => const BrowseScreen(),
          ),
          GoRoute(
            path: AppRoutes.myListings,
            builder: (_, __) => const MyListingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.createListing,
            builder: (_, __) => const CreateListingScreen(),
          ),
          GoRoute(
            path: AppRoutes.activity,
            builder: (_, __) => const FarmerActivityScreen(),
          ),
          GoRoute(
            path: AppRoutes.incomingOffers,
            builder: (_, __) => const IncomingOffersScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, __) => const OrdersListScreen(),
          ),
          GoRoute(
            path: AppRoutes.orderDetail,
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return OrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.help,
            builder: (_, __) => const HelpScreen(),
          ),
          GoRoute(
            path: AppRoutes.browseNeeds,
            builder: (_, __) => const BrowseNeedsScreen(),
          ),
          GoRoute(
            path: AppRoutes.postNeed,
            builder: (_, __) => const PostNeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.communityOrders,
            builder: (_, __) => const CommunityOrdersListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/company',
        builder: (_, __) => const HomeShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const HomeShell(),
      ),
    ],
  );
});
