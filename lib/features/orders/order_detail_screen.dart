import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/order_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/transport_estimator.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/status_tracker.dart';
import '../disputes/screens/raise_dispute_screen.dart';
import 'controllers/orders_controller.dart';
import 'rate_order_screen.dart';

/// Farmer's order detail. Large status timeline, payment strip,
/// two actions max.
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final order = ref.watch(orderByIdProvider(orderId));
    final user = ref.watch(authProvider);

    if (order == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isBuyer = user.id == order.buyerId;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Order'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _paymentStrip(theme, order),
                  const SizedBox(height: 16),
                  _summary(theme, order, isBuyer),
                  const SizedBox(height: 20),
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _tracker(order),
                  const SizedBox(height: 20),
                  _route(theme, order),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _actionButton(context, ref, order, isBuyer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentStrip(RoleTheme theme, OrderModel order) {
    final (label, color, icon) = _paymentStatus(order);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _total(order),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _paymentStatus(OrderModel order) {
    const theme = RoleTheme.farmer;
    if (order.state == OrderState.paymentReleased ||
        order.state == OrderState.completed ||
        order.state == OrderState.rated) {
      return ('Paid', theme.primary, Icons.check_circle);
    }
    if (order.state == OrderState.paymentSecured) {
      return ('Payment secured', theme.primary, Icons.lock);
    }
    if (order.state == OrderState.disputed) {
      return ('Payment on hold', theme.danger, Icons.pause_circle);
    }
    return ('Pay on delivery', theme.accent, Icons.schedule);
  }

  Widget _summary(RoleTheme theme, OrderModel order, bool isBuyer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.resourceType,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBuyer ? 'from ${order.sellerName}' : 'to ${order.buyerName}',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${order.quantity} ${order.unit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'KES ${order.pricePerUnit.round()} / ${order.unit}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tracker(OrderModel order) {
    if (order.state.isBranch) {
      final label = switch (order.state) {
        OrderState.disputed => 'Problem — being reviewed',
        OrderState.declined => 'Declined',
        OrderState.expired => 'Expired',
        _ => order.state.label,
      };
      return StatusTracker(
        steps: const [],
        currentIndex: 0,
        terminalLabel: label,
      );
    }
    const flow = [
      OrderState.requested,
      OrderState.negotiation,
      OrderState.accepted,
      OrderState.paymentSecured,
      OrderState.pickupScheduled,
      OrderState.qualityConfirmed,
      OrderState.completed,
      OrderState.paymentReleased,
      OrderState.rated,
    ];
    final idx = flow.indexOf(order.state);
    return StatusTracker(
      steps: const [
        'Asked',
        'Talking',
        'Agreed',
        'Payment',
        'Pickup',
        'Quality',
        'Done',
        'Paid',
        'Rated',
      ],
      currentIndex: idx < 0 ? 0 : idx,
    );
  }

  Widget _route(RoleTheme theme, OrderModel order) {
    final km = TransportEstimator.distanceKm(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _routeLine(
            theme,
            Icons.agriculture_outlined,
            theme.primary,
            'From',
            order.pickupBroadLocation,
          ),
          const SizedBox(height: 10),
          _routeLine(
            theme,
            Icons.location_on,
            theme.accent,
            'To',
            order.deliveryBroadLocation,
          ),
          if (km > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.route_outlined, size: 16, color: theme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'About ${km.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _routeLine(
    RoleTheme theme,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    bool isBuyer,
  ) {
    final controller = ref.read(ordersControllerProvider);
    final label = _actionLabel(order.state, isBuyer);
    if (label == null) return const SizedBox.shrink();

    return FarmerActionButton(
      label: label,
      icon: _actionIcon(order.state),
      onPressed: () {
        if (order.state == OrderState.paymentReleased) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RateOrderScreen(orderId: order.id),
            ),
          );
          return;
        }
        if (order.state == OrderState.qualityConfirmed && isBuyer) {
          controller.advance(order.id);
          return;
        }
        if (order.state == OrderState.disputed) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RaiseDisputeScreen(order: order),
            ),
          );
          return;
        }
        controller.advance(order.id);
      },
    );
  }

  String? _actionLabel(OrderState state, bool isBuyer) {
    switch (state) {
      case OrderState.requested:
        return isBuyer ? null : 'Accept';
      case OrderState.negotiation:
        return isBuyer ? null : 'Accept';
      case OrderState.accepted:
        return isBuyer ? 'Pay now' : null;
      case OrderState.paymentSecured:
        return 'Waiting for pickup';
      case OrderState.pickupScheduled:
        return 'Waiting for delivery';
      case OrderState.qualityConfirmed:
        return isBuyer ? 'Confirm' : null;
      case OrderState.completed:
        return 'Release payment';
      case OrderState.paymentReleased:
        return 'Rate this order';
      default:
        return null;
    }
  }

  IconData _actionIcon(OrderState state) {
    switch (state) {
      case OrderState.paymentReleased:
        return Icons.star_outline;
      case OrderState.qualityConfirmed:
        return Icons.check;
      case OrderState.accepted:
        return Icons.payment;
      default:
        return Icons.arrow_forward;
    }
  }

  String _total(OrderModel order) {
    final total = order.quantity * order.pricePerUnit;
    final rounded = total.round();
    final s = rounded.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KES ${buf.toString()}';
  }
}
