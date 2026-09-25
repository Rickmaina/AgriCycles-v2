import '../core/constants/app_routes.dart';
import '../core/constants/enums.dart';
import '../data/models/user_model.dart';

/// Role home. Farmers land in the market-stall shell; company and admin
/// land in the cockpit HomeShell.
String homeRouteFor(UserRole role) {
  switch (role) {
    case UserRole.company:
      return AppRoutes.companyHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.farmer:
    case UserRole.vet:
      return AppRoutes.home;
  }
}

bool isAuthLocation(String location) =>
    location == AppRoutes.login || location == AppRoutes.register;

bool isOnboardingLocation(String location) =>
    location == AppRoutes.onboarding ||
    location == AppRoutes.onboardingLocation ||
    location == AppRoutes.onboardingComplete;

bool isCockpitLocation(String location) =>
    location == AppRoutes.companyHome || location == AppRoutes.adminHome;

/// Pure redirect logic for go_router.
String? redirectFor({
  required UserModel? user,
  required String location,
}) {
  final loggedIn = user != null;
  final atAuth = isAuthLocation(location);

  if (!loggedIn && !atAuth) return AppRoutes.login;

  if (loggedIn) {
    final home = homeRouteFor(user.role);
    final needsOnboarding =
        user.role == UserRole.farmer && user.farmerType == null;

    if (atAuth) {
      return needsOnboarding ? AppRoutes.onboarding : home;
    }

    if (needsOnboarding && !isOnboardingLocation(location)) {
      return AppRoutes.onboarding;
    }

    if (!needsOnboarding && isOnboardingLocation(location)) {
      return home;
    }

    final farmer = user.role == UserRole.farmer || user.role == UserRole.vet;
    if (farmer && isCockpitLocation(location)) return AppRoutes.home;
    if (!farmer && !isCockpitLocation(location) && !atAuth) {
      return home;
    }
  }

  return null;
}
