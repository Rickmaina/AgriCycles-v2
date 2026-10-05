import 'geo_location.dart';

/// Company-specific profile data. Kept separate from [UserModel] so
/// the base identity stays lean and the company extension is opt-in.
///
/// When the backend is ready, this can become a separate document
/// keyed by `user_id` (or fold into the contract's `company_profile_detail`
/// table).
class CompanyProfileModel {
  final String businessName;
  final String businessType;
  final String contactName;
  final String? descriptor;
  final GeoLocation base;
  final DateTime updatedAt;

  const CompanyProfileModel({
    required this.businessName,
    required this.businessType,
    required this.contactName,
    this.descriptor,
    required this.base,
    required this.updatedAt,
  });

  CompanyProfileModel copyWith({
    String? businessName,
    String? businessType,
    String? contactName,
    String? descriptor,
    GeoLocation? base,
    DateTime? updatedAt,
  }) {
    return CompanyProfileModel(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      contactName: contactName ?? this.contactName,
      descriptor: descriptor ?? this.descriptor,
      base: base ?? this.base,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
