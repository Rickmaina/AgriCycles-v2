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
  final atAuth = location == AppRoutes.login ||
      location == AppRoutes.register;

  // Not logged in → force login
  if (!loggedIn && !atAuth) return AppRoutes.login;

  // Determine if this user still needs onboarding
  final needsOnboarding = loggedIn &&
      user.role.name == 'farmer' && // avoid importing UserRole here
      user.farmerType == null;

  // Logged in but sitting on an auth screen → push onward
  if (loggedIn && atAuth) {
    return needsOnboarding ? AppRoutes.onboarding : AppRoutes.home;
  }

  // Logged-in farmer without farmer type → onboarding
  if (loggedIn && needsOnboarding && location != AppRoutes.onboarding) {
    return AppRoutes.onboarding;
  }

  // Onboarding done but still on onboarding screen → home
  if (loggedIn && !needsOnboarding && location == AppRoutes.onboarding) {
    return AppRoutes.home;
  }

  return null;
}
