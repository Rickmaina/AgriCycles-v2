import '../core/constants/app_routes.dart';
import '../data/models/user_model.dart';

/// Pure redirect logic for go_router. Given the current user and the
/// requested location, decides where the user should actually be.
///
/// Returns null when no redirect is needed.
String? redirectFor({
  required UserModel? user,
  required String location,
}) {
  final loggedIn = user != null;
  final atAuth = location == AppRoutes.login || location == AppRoutes.register;

  if (!loggedIn && !atAuth) return AppRoutes.login;
  final needsOnboarding = loggedIn &&
      user.role.name == 'farmer' && // avoid importing UserRole here
      user.farmerType == null;
  if (loggedIn && atAuth) {
    return needsOnboarding ? AppRoutes.onboarding : AppRoutes.home;
  }
  if (loggedIn && needsOnboarding && location != AppRoutes.onboarding) {
    return AppRoutes.onboarding;
  }
  if (loggedIn && !needsOnboarding && location == AppRoutes.onboarding) {
    return AppRoutes.home;
  }

  return null;
}
