import '../core/constants/app_routes.dart';
import '../core/constants/enums.dart';
import '../data/models/company_profile_model.dart';
import '../data/models/user_model.dart';

/// Pure redirect logic for go_router.
///
/// Given the current user, their company profile (if any), and the
/// requested location, decides where the user should actually be.
/// Returns null when no redirect is needed.
///
/// Onboarding gates:
///   Farmer: farmerType == null → /onboarding
///   Company: companyProfile == null → /onboarding/company
///            companyProfile != null && not approved → /company/pending
String? redirectFor({
  required UserModel? user,
  required CompanyProfileModel? companyProfile,
  required String location,
}) {
  final loggedIn = user != null;
  final atAuth = location == AppRoutes.login ||
      location == AppRoutes.register;
  final atOnboarding = location == AppRoutes.onboarding ||
      location == AppRoutes.onboardingLocation ||
      location == AppRoutes.onboardingComplete ||
      location == AppRoutes.companyOnboarding ||
      location == AppRoutes.companyPending;

  // Not logged in → force login
  if (!loggedIn && !atAuth) return AppRoutes.login;

  if (!loggedIn) return null;

  // ── Farmer gate ────────────────────────────────────────────
  if (user.role == UserRole.farmer) {
    final needsOnboarding = user.farmerType == null;

    if (atAuth) {
      return needsOnboarding ? AppRoutes.onboarding : AppRoutes.home;
    }
    if (needsOnboarding && !atOnboarding) return AppRoutes.onboarding;
    if (!needsOnboarding && atOnboarding) return AppRoutes.home;
    return null;
  }

  // ── Company gate ───────────────────────────────────────────
  if (user.role == UserRole.company) {
    final needsProfile = companyProfile == null;
    final awaitingVerification = !needsProfile &&
        user.verificationStatus != VerificationStatus.approved;

    if (atAuth) {
      if (needsProfile) return AppRoutes.companyOnboarding;
      if (awaitingVerification) return AppRoutes.companyPending;
      return AppRoutes.companyHome;
    }
    if (needsProfile && location != AppRoutes.companyOnboarding) {
      return AppRoutes.companyOnboarding;
    }
    if (awaitingVerification && location != AppRoutes.companyPending) {
      return AppRoutes.companyPending;
    }
    if (!needsProfile &&
        !awaitingVerification &&
        atOnboarding) {
      return AppRoutes.companyHome;
    }
    return null;
  }

  // ── Admin and vet — no onboarding gate ─────────────────────
  return null;
}

/// The route a role lands on after login (or after finishing onboarding).
String homeRouteFor(UserRole role) {
  switch (role) {
    case UserRole.farmer:
      return AppRoutes.home;
    case UserRole.company:
      return AppRoutes.companyHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.vet:
      return AppRoutes.home;
  }
}
