import '../../core/constants/enums.dart';

/// A payment submission awaiting admin verification.
///
/// Created when a buyer submits payment evidence via
/// PaymentCardScreen. Admin verifies or rejects via the Payments queue.
class PaymentVerificationModel {
  final String id;
  final String orderId;

  /// Order context — denormalised so the admin queue doesn't need to
  /// look up OrderModel per card.
  final String resourceType;
  final String buyerName;
  final String sellerName;
  final double amount;

  /// What the buyer submitted.
  final String method;      // 'mpesa' | 'bank' | 'cash'
  final String reference;   // M-Pesa code, txn ref, etc.
  final DateTime paymentDate;
  final String? note;

  /// Who actually sent the money. May differ from buyerName.
  final String? payerName;
  final String? payerAccount; // phone or account number

  /// Receipt screenshot ref (path/ID). Null if not uploaded.
  final String? screenshotRef;

  final List<String> evidenceRefs;

  /// Admin review.
  final PaymentStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  const PaymentVerificationModel({
    required this.id,
    required this.orderId,
    required this.resourceType,
    required this.buyerName,
    required this.sellerName,
    required this.amount,
    required this.method,
    required this.reference,
    required this.paymentDate,
    this.note,
    this.payerName,
    this.payerAccount,
    this.screenshotRef,
    this.evidenceRefs = const [],
    this.status = PaymentStatus.pending,
    required this.submittedAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  PaymentVerificationModel copyWith({
    PaymentStatus? status,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectionReason,
  }) {
    return PaymentVerificationModel(
      id: id,
      orderId: orderId,
      resourceType: resourceType,
      buyerName: buyerName,
      sellerName: sellerName,
      amount: amount,
      method: method,
      reference: reference,
      paymentDate: paymentDate,
      note: note,
      payerName: payerName,
      payerAccount: payerAccount,
      screenshotRef: screenshotRef,
      evidenceRefs: evidenceRefs,
      status: status ?? this.status,
      submittedAt: submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
