import '../../../core/constants/enums.dart';
import '../../models/user_model.dart';

/// Seed users so the app is usable without a backend.
/// Replace with an HTTP-backed repository in production.
class SeedData {
  SeedData._();

  static final List<UserModel> users = [
    const UserModel(
      id: 'u1',
      name: 'Grace Wanjiku',
      phone: '0712345678',
      role: UserRole.farmer,
      farmerType: FarmerType.animal,
      county: 'Kiambu',
      subCounty: 'Ruiru',
      area: 'Kamakis',
    ),
    const UserModel(
      id: 'u2',
      name: 'Dr. Otieno',
      phone: '0722111222',
      role: UserRole.vet,
      county: 'Nairobi',
      subCounty: 'Langata',
      area: 'Karen',
      verificationStatus: VerificationStatus.approved,
    ),
    const UserModel(
      id: 'u3',
      name: 'Kenya Sugarcane Co.',
      phone: '0733555888',
      email: 'ops@ksco.co.ke',
      role: UserRole.company,
      county: 'Kisumu',
      subCounty: 'Ahero',
      area: 'Kano',
      verificationStatus: VerificationStatus.approved,
    ),
    const UserModel(
      id: 'u4',
      name: 'Admin',
      phone: '0700000000',
      role: UserRole.admin,
      county: 'Nairobi',
      subCounty: 'CBD',
      area: 'Central',
    ),
  ];

  static UserModel? findByRole(UserRole role) {
    for (final u in users) {
      if (u.role == role) return u;
    }
    return null;
  }
}
