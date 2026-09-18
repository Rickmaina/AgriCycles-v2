import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/community_contribution_model.dart';
import '../../../data/models/pre_order_model.dart';
import '../../../data/services/pre_order_service.dart';

class PreOrderController {
  PreOrderController(this._ref);
  final Ref _ref;

  PreOrderService get _svc => _ref.read(preOrderProvider.notifier);

  PreOrderModel create({
    required String buyerId,
    required String buyerName,
    required bool buyerIsCompany,
    required String resourceType,
    required String category,
    required double targetQuantity,
    required String unit,
    required double offeredPricePerUnit,
    String? description,
    required String deliveryCounty,
    required String deliverySubCounty,
    required String deliveryArea,
    String? deliveryNotes,
    required DateTime deadline,
  }) {
    final preOrder = PreOrderModel(
      id: 'po${DateTime.now().millisecondsSinceEpoch}',
      buyerId: buyerId,
      buyerName: buyerName,
      buyerIsCompany: buyerIsCompany,
      resourceType: resourceType,
      category: category,
      targetQuantity: targetQuantity,
      unit: unit,
      offeredPricePerUnit: offeredPricePerUnit,
      description: description,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    _svc.create(preOrder);
    return preOrder;
  }

  void cancel(String preOrderId) =>
      _svc.updateStatus(preOrderId, PreOrderStatus.cancelled);

  CommunityContributionModel contribute({
    required PreOrderModel preOrder,
    required String farmerId,
    required String farmerName,
    required double quantity,
    required String pickupCounty,
    required String pickupSubCounty,
    required String pickupArea,
  }) =>
      _svc.contribute(
        preOrder: preOrder,
        farmerId: farmerId,
        farmerName: farmerName,
        quantity: quantity,
        pickupCounty: pickupCounty,
        pickupSubCounty: pickupSubCounty,
        pickupArea: pickupArea,
      );

  void acceptContribution(
    String contributionId, {
    required double acceptedQuantity,
  }) =>
      _svc.updateContributionStatus(
        contributionId,
        ContributionStatus.confirmed,
        acceptedQuantity: acceptedQuantity,
      );

  void rejectContribution(String contributionId) =>
      _svc.updateContributionStatus(
        contributionId,
        ContributionStatus.rejected,
      );

  double progress(String preOrderId) => _svc.progress(preOrderId);
  double totalCommitted(String preOrderId) => _svc.totalCommitted(preOrderId);
  double totalConfirmed(String preOrderId) => _svc.totalConfirmed(preOrderId);
  bool isTargetMet(String preOrderId) => _svc.isTargetMet(preOrderId);
}

final preOrderControllerProvider =
    Provider<PreOrderController>((ref) => PreOrderController(ref));

final openPreOrdersProvider = Provider<List<PreOrderModel>>(
  (ref) => ref
      .watch(preOrderProvider)
      .preOrders
      .where((p) => p.status == PreOrderStatus.open)
      .toList(),
);

final myPreOrdersProvider =
    Provider.family<List<PreOrderModel>, String>((ref, buyerId) {
  return ref
      .watch(preOrderProvider)
      .preOrders
      .where((p) => p.buyerId == buyerId)
      .toList();
});

final preOrderByIdProvider = Provider.family<PreOrderModel?, String>((ref, id) {
  for (final p in ref.watch(preOrderProvider).preOrders) {
    if (p.id == id) return p;
  }
  return null;
});

final contributionsForProvider =
    Provider.family<List<CommunityContributionModel>, String>(
        (ref, preOrderId) {
  return ref
      .watch(preOrderProvider)
      .contributions
      .where((c) => c.preOrderId == preOrderId)
      .toList();
});
