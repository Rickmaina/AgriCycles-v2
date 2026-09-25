import 'geo_location.dart';
import '../../core/constants/enums.dart';

class ListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String resourceType;
  final String category;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String? description;
  final String? photoUrl;
  final GeoLocation location;
  final VerificationStatus sellerVerification;
  final ListingStatus status;

  /// Populated when [status] is [ListingStatus.rejected]. Null otherwise.
  final String? rejectionReason;

  /// Populated when the listing has been approved. Null while pending.
  final DateTime? reviewedAt;
  final String? reviewedBy;

  ListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.resourceType,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    this.description,
    this.photoUrl,
    GeoLocation? location,
    String? county,
    String? subCounty,
    String? area,
    this.sellerVerification = VerificationStatus.unverified,
    this.status = ListingStatus.pendingReview,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
  }) : location = location ??
            GeoLocation(
              county: county ?? '',
              subCounty: subCounty ?? '',
              area: area ?? '',
            );

  String get county => location.county;
  String get subCounty => location.subCounty;
  String get area => location.area;

  /// Only broad location is ever shown publicly (Section 8.1 of the
  /// design brief).
  String get broadLocation => location.broadLocation;

  /// True when this listing should appear in public browse/search.
  /// Pending-review and rejected listings do not.
  bool get isVisibleToPublic => status == ListingStatus.active;

  /// True when an admin needs to look at this listing.
  bool get needsReview =>
      status == ListingStatus.pendingReview || status == ListingStatus.rejected;

  ListingModel copyWith({
    String? resourceType,
    String? category,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? description,
    String? photoUrl,
    GeoLocation? location,
    String? county,
    String? subCounty,
    String? area,
    ListingStatus? status,
    String? rejectionReason,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    final nextLocation = location ??
        GeoLocation(
          county: county ?? this.location.county,
          subCounty: subCounty ?? this.location.subCounty,
          area: area ?? this.location.area,
        );

    return ListingModel(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      resourceType: resourceType ?? this.resourceType,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      location: nextLocation,
      sellerVerification: sellerVerification,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}
