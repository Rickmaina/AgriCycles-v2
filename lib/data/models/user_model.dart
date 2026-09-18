import '../../core/constants/enums.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final FarmerType? farmerType;
  final String? cropDetails;
  final String? county;
  final String? subCounty;
  final String? area;
  final VerificationStatus verificationStatus;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.farmerType,
    this.cropDetails,
    this.county,
    this.subCounty,
    this.area,
    this.verificationStatus = VerificationStatus.unverified,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    FarmerType? farmerType,
    String? cropDetails,
    String? county,
    String? subCounty,
    String? area,
    VerificationStatus? verificationStatus,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      farmerType: farmerType ?? this.farmerType,
      cropDetails: cropDetails ?? this.cropDetails,
      county: county ?? this.county,
      subCounty: subCounty ?? this.subCounty,
      area: area ?? this.area,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
