import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../data/services/auth_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/get_started_screen.dart';
import '../features/onboarding/onboarding_complete_screen.dart';
import 'route_guards.dart';

/// Bridges Riverpod auth state to a Listenable go_router can refresh on.
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
      return redirectFor(
        user: user,
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
        path: AppRoutes.onboardingComplete,
        builder: (_, __) => const OnboardingCompleteScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (_, __) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeShell(),
      ),
    ],
  );
});
