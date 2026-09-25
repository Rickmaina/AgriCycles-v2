import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/auth_service.dart';

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  static final _log = Logger.of('AuthController');

  AuthService get _service => _ref.read(authProvider.notifier);

  // ─── LOGIN ────────────────────────────────────────────────
  Future<Result<UserSnapshot>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final user = await _service.login(phone: phone, password: password);
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

  // ─── REGISTER ─────────────────────────────────────────────
  /// Registers a new account. Returns a [UserSnapshot] so callers can
  /// route identically to login.
  Future<Result<UserSnapshot>> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    UserRole role = UserRole.farmer,
    String? county,
    String? subCounty,
  }) async {
    try {
      final user = await _service.register(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
        role: role,
        county: county,
        subCounty: subCounty,
      );
      return Success(UserSnapshot(
        id: user.id,
        role: user.role,
        needsOnboarding: user.role == UserRole.farmer &&
            user.farmerType == null,
      ));
    } on AppFailure catch (e) {
      _log.warn('register failed: ${e.message}');
      return Failure(e);
    } catch (e, st) {
      _log.error('register unexpected', e, st);
      return const Failure(UnknownFailure('Could not create account'));
    }
  }

  // ─── UPDATE PROFILE ───────────────────────────────────────
  Future<Result<void>> updateProfile({
    String? fullName,
    String? email,
    String? county,
    String? subCounty,
  }) async {
    try {
      await _service.updateProfile(
        fullName: fullName,
        email: email,
        county: county,
        subCounty: subCounty,
      );
      return const Success(null);
    } on AppFailure catch (e) {
      return Failure(e);
    } catch (e, st) {
      _log.error('updateProfile unexpected', e, st);
      return const Failure(UnknownFailure());
    }
  }

  // ─── ONBOARDING (local only for now) ──────────────────────
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

  // ─── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
  }
}

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