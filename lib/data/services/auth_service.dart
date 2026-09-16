import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/errors/app_failure.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';
import 'mock/mock_data.dart';

/// Frontend-only auth. Holds the current user in memory.
/// Swap this class for an HTTP-backed implementation later without
/// touching any screen — every screen reads `authProvider`, not this class.
class AuthService extends StateNotifier<UserModel?> {
  AuthService() : super(null);

  static final _log = Logger.of('AuthService');

  /// Fake login for demo. Throws [AuthFailure] if the role has no seed user.
  Future<UserModel> loginAsRole(UserRole role) async {
    _log.info('login attempt role=${role.name}');
    await Future.delayed(const Duration(milliseconds: 250));
    final user = MockData.findByRole(role);
    if (user == null) {
      _log.warn('no seed user for role=${role.name}');
      throw AuthFailure('No demo account for ${role.label}');
    }
    state = user;
    _log.info('logged in as ${user.name}');
    return user;
  }

  Future<UserModel> registerFarmer({
    required String name,
    required String phone,
    String? email,
    required String county,
    required String subCounty,
    required String area,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final user = UserModel(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email,
      role: UserRole.farmer,
      county: county,
      subCounty: subCounty,
      area: area,
    );
    state = user;
    _log.info('registered farmer ${user.name}');
    return user;
  }

  void completeOnboarding({
    required FarmerType farmerType,
    String? cropDetails,
  }) {
    final u = state;
    if (u == null) return;
    state = u.copyWith(farmerType: farmerType, cropDetails: cropDetails);
  }

  void logout() {
    _log.info('logout');
    state = null;
  }
}

final authProvider =
    StateNotifierProvider<AuthService, UserModel?>((ref) => AuthService());
