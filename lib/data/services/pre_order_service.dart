import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/enums.dart';

import '../models/community_contribution_model.dart';
import '../models/pre_order_model.dart';
import '../models/geo_location.dart';

class PreOrderState {
  final List<PreOrderModel> preOrders;
  final List<CommunityContributionModel> contributions;

  const PreOrderState({
    required this.preOrders,
    required this.contributions,
  });

  PreOrderState copyWith({
    List<PreOrderModel>? preOrders,
    List<CommunityContributionModel>? contributions,
  }) =>
      PreOrderState(
        preOrders: preOrders ?? this.preOrders,
        contributions: contributions ?? this.contributions,
      );
}

class PreOrderService extends StateNotifier<PreOrderState> {
  PreOrderService()
      : super(PreOrderState(
          preOrders: _seedPreOrders(),
          contributions: _seedContributions(),
        ));

  static List<PreOrderModel> _seedPreOrders() {
    final now = DateTime.now();
    return [
      PreOrderModel(
        id: 'po1',
        buyerId: 'u3',
        buyerName: 'Kenya Sugarcane Co.',
        buyerIsCompany: true,
        resourceType: 'Maize stalks',
        category: 'Crop residue',
        targetQuantity: 20,
        unit: 'tonnes',
        offeredPricePerUnit: 4000,
        description:
            'Aggregate across farms. Pickup coordinated by Admin.',
        deliveryLocation: GeoLocation(
          county: 'Kisumu',
          subCounty: 'Nyando',
          area: 'Ahero',
        ),
        deadline: now.add(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 2)),
        status: PreOrderStatus.open,
      ),
      PreOrderModel(
        id: 'po2',
        buyerId: 'u10',
        buyerName: 'Rift Valley Dairy',
        buyerIsCompany: true,
        resourceType: 'Cow manure',
        category: 'Animal waste',
        targetQuantity: 10,
        unit: 'tonnes',
        offeredPricePerUnit: 1800,
        description: 'Need 10 tonnes for composting. Bulk price.',
        deliveryLocation: GeoLocation(
          county: 'Nakuru',
          subCounty: 'Naivasha',
          area: 'Industrial Area',
        ),
        deadline: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 1)),
        status: PreOrderStatus.open,
      ),
    ];
  }

  static List<CommunityContributionModel> _seedContributions() {
    final now = DateTime.now();
    return [
      CommunityContributionModel(
        id: 'cc1',
        preOrderId: 'po1',
        farmerId: 'u1',
        farmerName: 'Grace Wanjiku',
        committedQuantity: 3,
        acceptedQuantity: 3,
        pricePerUnit: 4000,
        pickupLocation: GeoLocation(
          county: 'Kiambu',
          subCounty: 'Ruiru',
          area: 'Kamakis',
        ),
        status: ContributionStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CommunityContributionModel(
        id: 'cc2',
        preOrderId: 'po1',
        farmerId: 'u5',
        farmerName: 'Joseph Mwangi',
        committedQuantity: 2.5,
        acceptedQuantity: 2.5,
        pricePerUnit: 4000,
        pickupLocation: GeoLocation(
          county: 'Kakamega',
          subCounty: 'Mumias West',
          area: 'Mumias Central',
        ),
        status: ContributionStatus.confirmed,
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      CommunityContributionModel(
        id: 'cc3',
        preOrderId: 'po1',
        farmerId: 'u7',
        farmerName: 'Mary Njeri',
        committedQuantity: 1.5,
        pricePerUnit: 4000,
        pickupLocation: GeoLocation(
          county: 'Kiambu',
          subCounty: 'Gatundu North',
          area: 'Gituamba',
        ),
        status: ContributionStatus.committed,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      CommunityContributionModel(
        id: 'cc4',
        preOrderId: 'po2',
        farmerId: 'u1',
        farmerName: 'Grace Wanjiku',
        committedQuantity: 4,
        pricePerUnit: 1800,
        pickupLocation: GeoLocation(
          county: 'Kiambu',
          subCounty: 'Ruiru',
          area: 'Kamakis',
        ),
        status: ContributionStatus.committed,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }

  void create(PreOrderModel preOrder) {
    state = state.copyWith(preOrders: [preOrder, ...state.preOrders]);
  }

  List<PreOrderModel> openPreOrders() =>
      state.preOrders.where((p) => p.status == PreOrderStatus.open).toList();

  List<PreOrderModel> byBuyer(String buyerId) =>
      state.preOrders.where((p) => p.buyerId == buyerId).toList();

  PreOrderModel? byId(String id) {
    for (final p in state.preOrders) {
      if (p.id == id) return p;
    }
    return null;
  }

  void updateStatus(String preOrderId, PreOrderStatus status) {
    state = state.copyWith(
      preOrders: state.preOrders
          .map((p) => p.id == preOrderId ? p.copyWith(status: status) : p)
          .toList(),
    );
  }

  List<CommunityContributionModel> contributionsFor(String preOrderId) =>
      state.contributions.where((c) => c.preOrderId == preOrderId).toList();

  List<CommunityContributionModel> contributionsByFarmer(String farmerId) =>
      state.contributions.where((c) => c.farmerId == farmerId).toList();

  /// Sum of committed quantities (regardless of status) for a pre-order.
  double totalCommitted(String preOrderId) => contributionsFor(preOrderId)
      .where((c) =>
          c.status == ContributionStatus.committed ||
          c.status == ContributionStatus.confirmed)
      .fold<double>(0, (sum, c) => sum + c.committedQuantity);

  /// Sum of confirmed quantities (post-buyer review).
  double totalConfirmed(String preOrderId) => contributionsFor(preOrderId)
      .where((c) => c.status == ContributionStatus.confirmed)
      .fold<double>(0, (sum, c) => sum + c.effectiveQuantity);

  /// 0.0 – 1.0 progress toward the target.
  double progress(String preOrderId) {
    final p = byId(preOrderId);
    if (p == null || p.targetQuantity <= 0) return 0;
    return (totalCommitted(preOrderId) / p.targetQuantity).clamp(0.0, 1.0);
  }

  bool isTargetMet(String preOrderId) {
    final p = byId(preOrderId);
    if (p == null) return false;
    return totalCommitted(preOrderId) >= p.targetQuantity;
  }

  /// Adds a commitment. Locks the pre-order automatically when the
  /// target is reached, per the order's rules.
  CommunityContributionModel contribute({
    required PreOrderModel preOrder,
    required String farmerId,
    required String farmerName,
    required double quantity,
    GeoLocation? pickupLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupSubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupArea,
  }) {
    final contribution = CommunityContributionModel(
      id: 'cc${DateTime.now().millisecondsSinceEpoch}',
      preOrderId: preOrder.id,
      farmerId: farmerId,
      farmerName: farmerName,
      committedQuantity: quantity,
      pricePerUnit: preOrder.offeredPricePerUnit,
      pickupLocation: pickupLocation,
      pickupCounty: pickupCounty,
      pickupSubCounty: pickupSubCounty,
      pickupArea: pickupArea,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      contributions: [contribution, ...state.contributions],
    );

    if (isTargetMet(preOrder.id)) {
      updateStatus(preOrder.id, PreOrderStatus.locked);
    }
    return contribution;
  }

  void updateContributionStatus(
    String contributionId,
    ContributionStatus status, {
    double? acceptedQuantity,
  }) {
    state = state.copyWith(
      contributions: state.contributions
          .map((c) => c.id == contributionId
              ? c.copyWith(
                  status: status,
                  acceptedQuantity: acceptedQuantity,
                )
              : c)
          .toList(),
    );
  }
}

final preOrderProvider = StateNotifierProvider<PreOrderService, PreOrderState>(
  (ref) => PreOrderService(),
);
