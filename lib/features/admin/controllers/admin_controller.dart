import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/verification_request_model.dart';
import '../../../data/services/verification_service.dart';

/// Thin controller over [VerificationService]. Admin screens call
/// approve / reject / submit through here.
class AdminController {
  AdminController(this._ref);
  final Ref _ref;

  VerificationService get _svc => _ref.read(verificationProvider.notifier);

  void approve(String requestId, String adminName) =>
      _svc.approve(requestId, adminName);

  void reject(String requestId, String adminName, String reason) =>
      _svc.reject(requestId, adminName, reason);

  void submit(VerificationRequestModel request) => _svc.submit(request);
}

final adminControllerProvider =
    Provider<AdminController>((ref) => AdminController(ref));

// ── Derived providers ─────────────────────────────────────────────

/// Pending items only, optionally filtered by type.
final pendingVerificationsProvider =
    Provider.family<List<VerificationRequestModel>, VerificationType?>(
  (ref, type) {
    final all = ref.watch(verificationProvider);
    return all.where((r) {
      if (r.status != VerificationStatus.pending) return false;
      if (type == null) return true;
      return r.type == type;
    }).toList();
  },
);
