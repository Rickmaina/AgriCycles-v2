/// Platform-wide behaviour rules, editable by admin.
///
/// These govern how flows operate (bidding, windows, commission), not
/// what things cost. Standard prices live in their own model.
class PlatformRulesModel {
  final double maxBidIncrementPct;
  final int counterOfferLimit;
  final int offerExpiryHours;
  final int paymentWindowHours;
  final double commissionPct;
  final double minListingAmountKes;

  final bool listingsNeedReview;
  final bool communityOrdersEnabled;
  final bool driverAutoAssign;
  final bool hotDemandAlerts;

  const PlatformRulesModel({
    required this.maxBidIncrementPct,
    required this.counterOfferLimit,
    required this.offerExpiryHours,
    required this.paymentWindowHours,
    required this.commissionPct,
    required this.minListingAmountKes,
    required this.listingsNeedReview,
    required this.communityOrdersEnabled,
    required this.driverAutoAssign,
    required this.hotDemandAlerts,
  });

  static const PlatformRulesModel defaults = PlatformRulesModel(
    maxBidIncrementPct: 30,
    counterOfferLimit: 5,
    offerExpiryHours: 48,
    paymentWindowHours: 24,
    commissionPct: 4.5,
    minListingAmountKes: 500,
    listingsNeedReview: true,
    communityOrdersEnabled: true,
    driverAutoAssign: false,
    hotDemandAlerts: true,
  );

  PlatformRulesModel copyWith({
    double? maxBidIncrementPct,
    int? counterOfferLimit,
    int? offerExpiryHours,
    int? paymentWindowHours,
    double? commissionPct,
    double? minListingAmountKes,
    bool? listingsNeedReview,
    bool? communityOrdersEnabled,
    bool? driverAutoAssign,
    bool? hotDemandAlerts,
  }) {
    return PlatformRulesModel(
      maxBidIncrementPct: maxBidIncrementPct ?? this.maxBidIncrementPct,
      counterOfferLimit: counterOfferLimit ?? this.counterOfferLimit,
      offerExpiryHours: offerExpiryHours ?? this.offerExpiryHours,
      paymentWindowHours: paymentWindowHours ?? this.paymentWindowHours,
      commissionPct: commissionPct ?? this.commissionPct,
      minListingAmountKes: minListingAmountKes ?? this.minListingAmountKes,
      listingsNeedReview: listingsNeedReview ?? this.listingsNeedReview,
      communityOrdersEnabled:
          communityOrdersEnabled ?? this.communityOrdersEnabled,
      driverAutoAssign: driverAutoAssign ?? this.driverAutoAssign,
      hotDemandAlerts: hotDemandAlerts ?? this.hotDemandAlerts,
    );
  }
}
