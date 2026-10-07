import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/verification_request_model.dart';
import '../../../data/services/verification_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/dispute_service.dart';
import '../../../data/services/payment_verification_service.dart';

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

// ─── Dashboard metrics ──────────────────────────────────────────────

/// One day's order count for the volume chart.
class OrderVolumePoint {
  final DateTime day;
  final int count;
  const OrderVolumePoint(this.day, this.count);
}

/// Last 7 days, oldest first, counting orders by createdAt.
final orderVolume7dProvider = Provider<List<OrderVolumePoint>>((ref) {
  final orders = ref.watch(ordersProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final points = <OrderVolumePoint>[];
  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final next = day.add(const Duration(days: 1));
    final count = orders
        .where((o) => !o.createdAt.isBefore(day) && o.createdAt.isBefore(next))
        .length;
    points.add(OrderVolumePoint(day, count));
  }
  return points;
});

/// One entry in the admin activity feed.
class ActivityEvent {
  final DateTime at;
  final String text;
  final ActivityTone tone;
  const ActivityEvent({required this.at, required this.text, required this.tone});
}

enum ActivityTone { info, success, warning, danger }

/// Top 8 recent events across orders, disputes, verifications, payments.
/// Derived from existing timestamps — no separate event bus.
final activityFeedProvider = Provider<List<ActivityEvent>>((ref) {
  final orders = ref.watch(ordersProvider);
  final disputes = ref.watch(disputeProvider);
  final verifications = ref.watch(verificationProvider);
  final payments = ref.watch(paymentVerificationProvider);

  final events = <ActivityEvent>[];

  for (final o in orders) {
    events.add(ActivityEvent(
      at: o.updatedAt,
      text: 'Order ${o.id.toUpperCase()} · ${o.state.label}',
      tone: ActivityTone.info,
    ));
  }

  for (final d in disputes) {
    events.add(ActivityEvent(
      at: d.updatedAt,
      text: 'Dispute on ${d.orderResourceType} · ${d.status.label}',
      tone: d.status == DisputeStatus.resolved
          ? ActivityTone.success
          : ActivityTone.danger,
    ));
  }

  for (final v in verifications) {
    events.add(ActivityEvent(
      at: v.reviewedAt ?? v.submittedAt,
      text: '${v.type.label} · ${v.applicantName} · ${v.status.name}',
      tone: v.status == VerificationStatus.approved
          ? ActivityTone.success
          : v.status == VerificationStatus.rejected
              ? ActivityTone.danger
              : ActivityTone.warning,
    ));
  }

  for (final p in payments) {
    events.add(ActivityEvent(
      at: p.verifiedAt ?? p.submittedAt,
      text: 'Payment ${p.reference} · ${p.status.label}',
      tone: p.status == PaymentStatus.verified
          ? ActivityTone.success
          : p.status == PaymentStatus.rejected
              ? ActivityTone.danger
              : ActivityTone.warning,
    ));
  }

  events.sort((a, b) => b.at.compareTo(a.at));
  return events.take(8).toList();
});
