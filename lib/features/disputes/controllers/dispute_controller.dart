import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/dispute_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/dispute_service.dart';
import '../../../data/services/order_service.dart';
import '../../notifications/controllers/notification_controller.dart';

class DisputeController {
  DisputeController(this._ref);
  final Ref _ref;

  DisputeService get _svc => _ref.read(disputeProvider.notifier);

  DisputeModel raise({
    required OrderModel order,
    required String raisedById,
    required String raisedByName,
    required DisputeIssueType issueType,
    required String description,
    double? affectedQuantity,
    double? affectedAmount,
  }) {
    final role = raisedById == order.buyerId ? 'buyer' : 'seller';
    final now = DateTime.now();
    final dispute = DisputeModel(
      id: 'd${now.millisecondsSinceEpoch}',
      orderId: order.id,
      orderResourceType: order.resourceType,
      raisedById: raisedById,
      raisedByName: raisedByName,
      raisedByRole: role,
      issueType: issueType,
      description: description,
      affectedQuantity: affectedQuantity,
      affectedAmount: affectedAmount,
      createdAt: now,
      updatedAt: now,
    );
    _svc.raise(dispute);

    _ref.read(ordersProvider.notifier).branchTo(order.id, OrderState.disputed);

    final notify = _ref.read(notificationControllerProvider);
    notify.notifyDispute(
      recipientId: order.buyerId,
      disputeId: dispute.id,
      orderResourceType: order.resourceType,
      message: '${issueType.label} dispute raised',
    );
    notify.notifyDispute(
      recipientId: order.sellerId,
      disputeId: dispute.id,
      orderResourceType: order.resourceType,
      message: '${issueType.label} dispute raised',
    );

    return dispute;
  }

  void markUnderReview(String disputeId) => _svc.markUnderReview(disputeId);

  void resolve({
    required String disputeId,
    required DisputeResolution resolution,
    required String adminName,
    String? notes,
  }) =>
      _svc.resolve(
        disputeId: disputeId,
        resolution: resolution,
        adminName: adminName,
        notes: notes,
      );
}

final disputeControllerProvider =
    Provider<DisputeController>((ref) => DisputeController(ref));

final openDisputesProvider = Provider<List<DisputeModel>>(
  (ref) => ref
      .watch(disputeProvider)
      .where((d) => d.status != DisputeStatus.resolved)
      .toList(),
);

final disputesForOrderProvider = Provider.family<List<DisputeModel>, String>(
  (ref, orderId) =>
      ref.watch(disputeProvider).where((d) => d.orderId == orderId).toList(),
);

final disputeByIdProvider = Provider.family<DisputeModel?, String>((ref, id) {
  for (final d in ref.watch(disputeProvider)) {
    if (d.id == id) return d;
  }
  return null;
});
