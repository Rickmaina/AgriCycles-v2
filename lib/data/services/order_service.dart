import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/logger.dart';
import '../../domain/order_state_machine.dart';
import '../models/order_model.dart';
import 'mock/mock_orders.dart';

class OrderService extends StateNotifier<List<OrderModel>> {
  OrderService() : super(List.of(MockOrders.all));

  static final _log = Logger.of('OrderService');

  // ── Queries ───────────────────────────────────────────────────

  List<OrderModel> asBuyer(String userId) =>
      state.where((o) => o.buyerId == userId).toList();

  List<OrderModel> asSeller(String userId) =>
      state.where((o) => o.sellerId == userId).toList();

  List<OrderModel> forUser(String userId) => state
      .where((o) => o.buyerId == userId || o.sellerId == userId)
      .toList();

  OrderModel? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ── Mutations ─────────────────────────────────────────────────

  /// Advance a single order to a specific state. Logistics sub-state is
  /// derived from [OrderStateMachine.logisticsFor]. Silently no-ops if
  /// the order does not exist.
  void advanceTo(String orderId, OrderState next) {
    state = state.map((o) {
      if (o.id != orderId) return o;
      _log.info('advance ${o.id}: ${o.state.name} -> ${next.name}');
      return o.copyWith(
        state: next,
        logisticsState:
            OrderStateMachine.logisticsFor(next) ?? o.logisticsState,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  /// Move an order into a branch state (declined / expired / disputed).
  void branchTo(String orderId, OrderState branch) {
    final validBranches =
        OrderStateMachine.branchTransitions.values.expand((e) => e).toSet();
    if (!validBranches.contains(branch)) {
      _log.warn('attempted invalid branch: ${branch.name}');
      return;
    }
    state = state.map((o) {
      if (o.id != orderId) return o;
      _log.info('branch ${o.id}: ${o.state.name} -> ${branch.name}');
      return o.copyWith(state: branch, updatedAt: DateTime.now());
    }).toList();
  }

  /// Creates an order from an accepted offer. The order starts at
  /// [OrderState.accepted] — the seller has just accepted the buyer's
  /// terms.
  OrderModel createFromOffer({
    required String listingId,
    required String resourceType,
    required String unit,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    required double quantity,
    required double pricePerUnit,
    required String pickupCounty,
    required String pickupSubCounty,
    required String pickupArea,
    required String deliveryCounty,
    required String deliverySubCounty,
    required String deliveryArea,
    String? deliveryNotes,
  }) {
    final now = DateTime.now();
    final order = OrderModel(
      id: 'ord${now.millisecondsSinceEpoch}',
      listingId: listingId,
      resourceType: resourceType,
      unit: unit,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      state: OrderState.accepted,
      createdAt: now,
      updatedAt: now,
      pickupCounty: pickupCounty,
      pickupSubCounty: pickupSubCounty,
      pickupArea: pickupArea,
      deliveryCounty: deliveryCounty,
      deliverySubCounty: deliverySubCounty,
      deliveryArea: deliveryArea,
      deliveryNotes: deliveryNotes,
    );
    state = [order, ...state];
    _log.info('created order ${order.id} from offer');
    return order;
  }
}

final ordersProvider =
    StateNotifierProvider<OrderService, List<OrderModel>>(
  (ref) => OrderService(),
);
