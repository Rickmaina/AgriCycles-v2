import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/geo_location.dart';
import '../../../data/services/order_service.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../../domain/order_state_machine.dart';

/// Wraps [OrderService] and the state machine so screens never touch
/// either directly. Every advance/branch goes through here.
class OrdersController {
  OrdersController(this._ref);
  final Ref _ref;

  OrderService get _svc => _ref.read(ordersProvider.notifier);

  /// Advances a healthy order one step forward. Silently no-ops if the
  /// order is in a branch or terminal state.
  void advance(String orderId) {
    final order = _svc.byId(orderId);
    if (order == null) return;
    final next = OrderStateMachine.nextState(order.state);
    if (next == null) return;
    _svc.advanceTo(orderId, next);

    final notify = _ref.read(notificationControllerProvider);
    notify.notifyOrder(
      recipientId: order.buyerId,
      orderId: order.id,
      resourceType: order.resourceType,
      state: next,
    );
    notify.notifyOrder(
      recipientId: order.sellerId,
      orderId: order.id,
      resourceType: order.resourceType,
      state: next,
    );
  }

  /// Moves an order into a branch state (declined / expired / disputed).
  void branch(String orderId, OrderState branchState) {
    _svc.branchTo(orderId, branchState);
  }

  /// Convenience: creates an order from an accepted offer.
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
    GeoLocation? pickupLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupSubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? pickupArea,
    GeoLocation? deliveryLocation,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliverySubCounty,
    @Deprecated('Migrate to GeoLocation — see privacy_coordinates.md')
    String? deliveryArea,
    String? deliveryNotes,
  }) =>
      _svc.createFromOffer(
        listingId: listingId,
        resourceType: resourceType,
        unit: unit,
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: sellerId,
        sellerName: sellerName,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        pickupLocation: pickupLocation,
        pickupCounty: pickupCounty,
        pickupSubCounty: pickupSubCounty,
        pickupArea: pickupArea,
        deliveryLocation: deliveryLocation,
        deliveryCounty: deliveryCounty,
        deliverySubCounty: deliverySubCounty,
        deliveryArea: deliveryArea,
        deliveryNotes: deliveryNotes,
      );
}

final ordersControllerProvider =
    Provider<OrdersController>((ref) => OrdersController(ref));

final buyingOrdersProvider = Provider.family<List<OrderModel>, String>(
    (ref, userId) =>
        ref.watch(ordersProvider).where((o) => o.buyerId == userId).toList());

final sellingOrdersProvider = Provider.family<List<OrderModel>, String>(
    (ref, userId) =>
        ref.watch(ordersProvider).where((o) => o.sellerId == userId).toList());

final orderByIdProvider = Provider.family<OrderModel?, String>((ref, orderId) {
  for (final o in ref.watch(ordersProvider)) {
    if (o.id == orderId) return o;
  }
  return null;
});

/// Admin logistics queue: orders with a live logistics state that need
/// attention (awaiting assignment or awaiting delivery confirmation).
final logisticsQueueProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(ordersProvider).where((o) {
    return o.state == OrderState.paymentSecured ||
        o.state == OrderState.pickupScheduled;
  }).toList();
});
