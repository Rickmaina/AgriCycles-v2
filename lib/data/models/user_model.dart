import '../../core/constants/enums.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final FarmerType? farmerType;
  final String? cropDetails;
  final String? farmScale;
  final String? county;
  final String? subCounty;
  final String? area;
  final VerificationStatus verificationStatus;
  final double? averageRating;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.farmerType,
    this.cropDetails,
    this.farmScale,
    this.county,
    this.subCounty,
    this.area,
    this.verificationStatus = VerificationStatus.unverified,
    this.averageRating,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    FarmerType? farmerType,
    String? cropDetails,
    String? farmScale,
    String? county,
    String? subCounty,
    String? area,
    VerificationStatus? verificationStatus,
    double? averageRating,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      farmerType: farmerType ?? this.farmerType,
      cropDetails: cropDetails ?? this.cropDetails,
      farmScale: farmScale ?? this.farmScale,
      county: county ?? this.county,
      subCounty: subCounty ?? this.subCounty,
      area: area ?? this.area,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  // Add to user_model.dart

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: _roleFromApi(json['role'] as String),
      county: json['county'] as String?,
      subCounty: json['sub_county'] as String?,
      verificationStatus: _verificationFromApi(
        json['verification_status'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': name,
    'phone': phone,
    'email': email,
    'county': county,
    'sub_county': subCounty,
  };

// Mapping helpers
  static UserRole _roleFromApi(String api) {
    switch (api) {
      case 'farmer': return UserRole.farmer;
      case 'buyer':  return UserRole.company;  // API says "buyer", app says "company"
      case 'admin':  return UserRole.admin;
      default:       return UserRole.farmer;
    }
  }

  static VerificationStatus _verificationFromApi(String api) {
    switch (api) {
      case 'unverified': return VerificationStatus.unverified;
      case 'pending':    return VerificationStatus.pending;
      case 'verified':   return VerificationStatus.approved; // rename on the way in
      case 'rejected':   return VerificationStatus.rejected;
      default:           return VerificationStatus.unverified;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
