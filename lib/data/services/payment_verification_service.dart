import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/payment_verification_model.dart';

class PaymentVerificationService
    extends StateNotifier<List<PaymentVerificationModel>> {
  PaymentVerificationService() : super(_seed());

  static List<PaymentVerificationModel> _seed() {
    final now = DateTime.now();
    return [
      PaymentVerificationModel(
        id: 'pv1',
        orderId: 'ord0042',
        resourceType: 'Maize Stalks',
        buyerName: 'Kenya Sugarcane Co.',
        sellerName: 'Grace Wanjiku',
        amount: 47500,
        method: 'mpesa',
        reference: 'QHJ4K8X2R9',
        paymentDate: now.subtract(const Duration(hours: 3)),
        note: 'Paid in full',
        payerName: 'Kenya Sugarcane Co.',
        payerAccount: '+254 733 555 888',
        screenshotRef: 'mpesa_receipt_QHJ4K8X2R9.png',
        status: PaymentStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 3)),
      ),
      PaymentVerificationModel(
        id: 'pv2',
        orderId: 'ord0040',
        resourceType: 'Cow Manure',
        buyerName: 'GreenFeed Industries Ltd',
        sellerName: 'Peter Mwangi',
        amount: 31000,
        method: 'bank',
        reference: 'TXN-88231-AA',
        paymentDate: now.subtract(const Duration(hours: 20)),
        payerName: 'GreenFeed Industries Ltd',
        payerAccount: 'KCB 1102 445 678',
        screenshotRef: 'bank_slip_TXN-88231-AA.pdf',
        status: PaymentStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 20)),
      ),
    ];
  }

  void submit(PaymentVerificationModel model) {
    state = [model, ...state];
  }

  void verify(String id, String adminName) {
    _update(
      id,
      (p) => p.copyWith(
        status: PaymentStatus.verified,
        verifiedAt: DateTime.now(),
        verifiedBy: adminName,
      ),
    );
  }

  void reject(String id, String adminName, String reason) {
    _update(
      id,
      (p) => p.copyWith(
        status: PaymentStatus.rejected,
        verifiedAt: DateTime.now(),
        verifiedBy: adminName,
        rejectionReason: reason,
      ),
    );
  }

  void _update(
    String id,
    PaymentVerificationModel Function(PaymentVerificationModel) map,
  ) {
    state = state.map((p) => p.id == id ? map(p) : p).toList();
  }
}

final paymentVerificationProvider = StateNotifierProvider<
    PaymentVerificationService, List<PaymentVerificationModel>>(
  (ref) => PaymentVerificationService(),
);

/// Pending only — what the admin queue shows.
final pendingPaymentsProvider = Provider<List<PaymentVerificationModel>>(
  (ref) => ref
      .watch(paymentVerificationProvider)
      .where((p) => p.status == PaymentStatus.pending)
      .toList(),
);
