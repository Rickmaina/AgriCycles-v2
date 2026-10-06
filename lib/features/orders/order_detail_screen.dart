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
import 'payment_card_screen.dart';
import 'widgets/rate_order_dialogs.dart';

/// Role-aware order detail. Farmer sees a large visual timeline with
/// up to two actions. Company sees the same timeline with buyer CTAs.
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
    final isCompany = user.role == UserRole.company;

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
                  _paymentStrip(theme, order, isCompany),
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
                  if (!order.state.isTerminal &&
                      order.state != OrderState.rated) ...[
                    const SizedBox(height: 20),
                    _issueLink(context, order),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _actionButton(
                context,
                ref,
                order,
                isBuyer: isBuyer,
                isCompany: isCompany,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Payment strip
  // ─────────────────────────────────────────────────────────────
  Widget _paymentStrip(RoleTheme theme, OrderModel order, bool isCompany) {
    final (label, color, icon) = _paymentStatus(order, isCompany);
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

  (String, Color, IconData) _paymentStatus(
    OrderModel order,
    bool isCompany,
  ) {
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
    if (isCompany && order.state == OrderState.accepted) {
      return ('Submit payment proof', theme.accent, Icons.upload_file);
    }
    return ('Pay on delivery', theme.accent, Icons.schedule);
  }

  // ─────────────────────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────────────────────
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
            isBuyer
                ? 'from ${order.sellerName}'
                : 'to ${order.buyerName}',
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

  // ─────────────────────────────────────────────────────────────
  // Status tracker
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // Route
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // Issue link
  // ─────────────────────────────────────────────────────────────
  Widget _issueLink(BuildContext context, OrderModel order) {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RaiseDisputeScreen(order: order),
          ),
        ),
        icon: const Icon(Icons.report_problem_outlined, size: 18),
        label: const Text('Report a problem'),
        style: TextButton.styleFrom(
          foregroundColor: RoleTheme.farmer.danger,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Action button
  // ─────────────────────────────────────────────────────────────
  Widget _actionButton(
    BuildContext context,
    WidgetRef ref,
    OrderModel order, {
    required bool isBuyer,
    required bool isCompany,
  }) {
    final controller = ref.read(ordersControllerProvider);
    final (label, icon) = _actionLabel(order.state, isBuyer, isCompany);
    if (label == null) return const SizedBox.shrink();

    return FarmerActionButton(
      label: label,
      icon: icon,
      onPressed: () {
        // Rate path
        if (order.state == OrderState.paymentReleased) {
          showRateOrderDialog(
            context: context,
            ref: ref,
            orderId: order.id,
          );
          return;
        }

        // Payment path: buyer of an accepted order must submit evidence
        // before the state moves to paymentSecured.
        if (order.state == OrderState.accepted && isBuyer) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentCardScreen(
                orderId: order.id,
                amount: order.quantity * order.pricePerUnit,
                resourceName: order.resourceType,
              ),
            ),
          );
          return;
        }

        // All other state advances go through the controller
        controller.advance(order.id);
      },
    );
  }

  (String?, IconData) _actionLabel(
    OrderState state,
    bool isBuyer,
    bool isCompany,
  ) {
    switch (state) {
      case OrderState.requested:
        return isBuyer ? (null, Icons.arrow_forward) : ('Accept', Icons.check);
      case OrderState.negotiation:
        return isBuyer
            ? (null, Icons.arrow_forward)
            : ('Accept price', Icons.check);
      case OrderState.accepted:
        if (!isBuyer) return (null, Icons.arrow_forward);
        return isCompany
            ? ('Submit payment proof', Icons.upload_file)
            : ('Pay now', Icons.payment);
      case OrderState.paymentSecured:
        return ('Waiting for pickup', Icons.local_shipping_outlined);
      case OrderState.pickupScheduled:
        return ('Waiting for delivery', Icons.local_shipping_outlined);
      case OrderState.qualityConfirmed:
        return isBuyer
            ? (isCompany ? 'Confirm quality' : 'Confirm', Icons.check)
            : (null, Icons.arrow_forward);
      case OrderState.completed:
        return ('Release payment', Icons.payments_outlined);
      case OrderState.paymentReleased:
        return ('Rate this order', Icons.star_outline);
      default:
        return (null, Icons.arrow_forward);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
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
