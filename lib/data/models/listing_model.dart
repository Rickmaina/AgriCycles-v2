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
  final String county;
  final String subCounty;
  final String area;
  final VerificationStatus sellerVerification;
  final ListingStatus status;

  const ListingModel({
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
    required this.county,
    required this.subCounty,
    required this.area,
    this.sellerVerification = VerificationStatus.unverified,
    this.status = ListingStatus.active,
  });

  /// Only broad location is ever shown publicly (Section 8.1).
  String get broadLocation => '$area, $subCounty';

  ListingModel copyWith({
    String? resourceType,
    String? category,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? description,
    String? photoUrl,
    ListingStatus? status,
  }) {
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
      county: county,
      subCounty: subCounty,
      area: area,
      sellerVerification: sellerVerification,
      status: status ?? this.status,
    );
  }
}
