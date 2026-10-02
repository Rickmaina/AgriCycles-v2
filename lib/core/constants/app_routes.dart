/// Typed route paths. Never hardcode a path string in a screen.
class AppRoutes {
  AppRoutes._();

  // ── Auth & onboarding ───────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String onboardingLocation = '/onboarding/location';
  static const String onboardingComplete = '/onboarding/complete';

  // ── Farmer shell (all under FarmerShell) ────────────────────
  static const String home = '/home';
  static const String market = '/market';
  static const String browse = '/browse';
  static const String myListings = '/my-listings';
  static const String createListing = '/create-listing';
  static const String makeOffer = '/make-offer';
  static const String activity = '/activity';
  static const String incomingOffers = '/incoming-offers';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String help = '/help';

  // ── Buy requests ────────────────────────────────────────────
  static const String browseNeeds = '/browse-needs';
  static const String postNeed = '/post-need';

  // ── Community orders ────────────────────────────────────────
  static const String communityOrders = '/community-orders';

  // ── Company & admin ─────────────────────────────────────────
  static const String companyHome = '/company';
  static const String adminHome = '/admin';

  // ── Helper routes for notification deep-links ─────────────────
  static String orderDetail(String id) => '$orders/$id';
  static String disputeDetail(String id) => '/disputes/$id';
  static String communityOrderDetail(String id) => '$communityOrders/$id';
  static String listingDetail(String id) => '$browse?listing=$id';
  static String offerDetail(String id) => '$incomingOffers?offer=$id';
  static String verificationDetail(String id) => '$profile?verification=$id';
}
