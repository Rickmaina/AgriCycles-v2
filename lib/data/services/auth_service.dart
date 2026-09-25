import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/token_storage.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthService extends StateNotifier<UserModel?> {
  AuthService() : super(null);

  static final _log = Logger.of('AuthService');
  final _api = ApiClient.instance;

  // ─── LOGIN ────────────────────────────────────────────────
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    _log.info('login attempt phone=$phone');

    final data = await _api.post<Map<String, dynamic>>(
      ApiConfig.login,
      data: {'phone': phone, 'password': password},
    );

    return _persist(data);
  }

  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    UserRole role = UserRole.farmer,
    String? county,
    String? subCounty,
  }) async {
    // ⬇ DEBUG — remove after fixing
    // ignore: avoid_print
    print('REGISTER input: fullName="$fullName" phone="$phone" '
        'password=${password.length}chars email=$email role=${role.name} '
        'county=$county subCounty=$subCounty');

    final roleString = _roleToApi(role);

    // ignore: avoid_print
    print('REGISTER role → "$roleString"');

    final payload = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'password': password,
      if (email != null) 'email': email,
      'role': roleString,
      if (county != null) 'county': county,
      if (subCounty != null) 'sub_county': subCounty,
    };

    // ignore: avoid_print
    print('REGISTER payload → $payload');

    final data = await _api.post<Map<String, dynamic>>(
      ApiConfig.register,
      data: payload,
    );

    return _persist(data);
  }

// ⬇ Keep whatever _roleToApi you have. If you don't have one, here's the mapping:
  String _roleToApi(UserRole role) {
    switch (role) {
      case UserRole.farmer:  return 'farmer';
      case UserRole.company: return 'buyer';   // API calls it "buyer"
      case UserRole.admin:   return 'admin';
      case UserRole.vet:     return 'farmer';  // not supported yet
    }
  }

  // ─── UPDATE PROFILE ───────────────────────────────────────
  Future<UserModel> updateProfile({
    String? fullName,
    String? email,
    String? county,
    String? subCounty,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      ApiConfig.me,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (county != null) 'county': county,
        if (subCounty != null) 'sub_county': subCounty,
      },
    );
    final user = UserModel.fromJson(data);
    state = _mergeLocal(user);  // keep farmerType / cropDetails locally
    return state!;
  }

  // ─── REFRESH / ME ─────────────────────────────────────────
  Future<UserModel?> hydrate() async {
    final token = await TokenStorage.accessToken();
    if (token == null) return null;
    try {
      final data = await _api.get<Map<String, dynamic>>(ApiConfig.me);
      final user = UserModel.fromJson(data);
      state = user;
      return user;
    } catch (_) {
      await TokenStorage.clear();
      return null;
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    _log.info('logout');
    try {
      final rt = await TokenStorage.refreshToken();
      if (rt != null) {
        await _api.post(ApiConfig.logout, data: {'refresh_token': rt});
      }
    } catch (_) {
      // Idempotent — ignore failures
    }
    await TokenStorage.clear();
    state = null;
  }

  // ─── LOCAL ONLY (API doesn't cover yet) ───────────────────
  void completeOnboarding({
    required FarmerType farmerType,
    String? cropDetails,
    String? farmScale,
  }) {
    final u = state;
    if (u == null) return;
    state = u.copyWith(
      farmerType: farmerType,
      cropDetails: cropDetails,
      farmScale: farmScale,
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────
  Future<UserModel> _persist(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await TokenStorage.save(
      access: tokens['access_token'] as String,
      refresh: tokens['refresh_token'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    state = user;
    _log.info('logged in as ${user.name}');
    return user;
  }

  UserModel _mergeLocal(UserModel fromApi) {
    final old = state;
    if (old == null) return fromApi;
    return fromApi.copyWith(
      farmerType: old.farmerType,
      cropDetails: old.cropDetails,
    );
  }


}

final authProvider =
StateNotifierProvider<AuthService, UserModel?>((ref) => AuthService());