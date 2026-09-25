import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/auth_service.dart';

/// Sits between the UI and [AuthService]. Screens call methods here and
/// get back a [Result] they can pattern-match; they never reach into
/// the service directly.
class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  static final _log = Logger.of('AuthController');

  AuthService get _service => _ref.read(authProvider.notifier);

  /// Attempts to log in as the given role. Returns a [Result] so the
  /// caller can render an error message without try/catch.
  Future<Result<UserSnapshot>> loginAsRole(UserRole role) async {
    try {
      final user = await _service.loginAsRole(role);
      return Success(UserSnapshot(
        id: user.id,
        role: user.role,
        needsOnboarding:
            user.role == UserRole.farmer && user.farmerType == null,
      ));
    } on AppFailure catch (e) {
      _log.warn('login failed: ${e.message}');
      return Failure(e);
    } catch (e, st) {
      _log.error('login unexpected', e, st);
      return const Failure(UnknownFailure());
    }
  }

  /// Registers a new farmer account. Returns the same [UserSnapshot]
  /// shape so callers can route identically to login.
  Future<Result<UserSnapshot>> registerFarmer({
    required String name,
    required String phone,
    String? email,
    required String county,
    required String subCounty,
    required String area,
  }) async {
    try {
      final user = await _service.registerFarmer(
        name: name,
        phone: phone,
        email: email,
        county: county,
        subCounty: subCounty,
        area: area,
      );
      return Success(UserSnapshot(
        id: user.id,
        role: user.role,
        needsOnboarding: user.farmerType == null,
      ));
    } catch (e, st) {
      _log.error('register failed', e, st);
      return const Failure(UnknownFailure('Could not create account'));
    }
  }

  /// Completes the plant/animal onboarding step (Section 16.1).
  void completeOnboarding({
    required FarmerType farmerType,
    String? cropDetails,
    String? farmScale,
  }) {
    _service.completeOnboarding(
      farmerType: farmerType,
      cropDetails: cropDetails,
      farmScale: farmScale,
    );
  }

  void logout() => _service.logout();
}

/// The minimum a screen needs to know after login/register: who you are
/// and whether you still need onboarding.
class UserSnapshot {
  final String id;
  final UserRole role;
  final bool needsOnboarding;

  const UserSnapshot({
    required this.id,
    required this.role,
    required this.needsOnboarding,
  });
}

final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref));
