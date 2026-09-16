import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/order_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/order_state_machine.dart';
import '../../domain/transport_estimator.dart';
import '../../shared/widgets/status_tracker.dart';
import 'controllers/orders_controller.dart';
import 'rate_order_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      appBar: AppBar(title: Text('Order #${order.id.substring(3)}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SummaryCard(order: order, isBuyer: isBuyer),
          const SizedBox(height: 16),
          _RouteCard(order: order),
          const SizedBox(height: 20),
          const _SectionLabel('Status'),
          const SizedBox(height: 12),
          _buildTracker(order),
          if (_showLogistics(order)) ...[
            const SizedBox(height: 24),
            const _SectionLabel('Logistics'),
            const SizedBox(height: 12),
            _LogisticsCard(order: order),
          ],
          const SizedBox(height: 24),
          _ActionButton(order: order, isBuyer: isBuyer),
          const SizedBox(height: 8),
          const Text(
            'Contact details are shared only after acceptance and only between the two parties.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  bool _showLogistics(OrderModel order) =>
      order.state == OrderState.paymentSecured ||
      order.state == OrderState.pickupScheduled ||
      order.state == OrderState.qualityConfirmed;

  Widget _buildTracker(OrderModel order) {
    if (order.state.isBranch) {
      return StatusTracker(
        steps: const [],
        currentIndex: 0,
        terminalLabel: switch (order.state) {
          OrderState.disputed => 'Disputed — Admin is reviewing',
          OrderState.declined => 'Declined by seller',
          OrderState.expired => 'Expired — no action taken',
          _ => order.state.label,
        },
      );
    }
    final labels =
        OrderStateMachine.linearFlow.map((s) => s.label).toList();
    final idx = OrderStateMachine.stepIndex(order.state);
    return StatusTracker(steps: labels, currentIndex: idx);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final OrderModel order;
  final bool isBuyer;
  const _SummaryCard({required this.order, required this.isBuyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.resourceType,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isBuyer
                ? 'from ${order.sellerName}'
                : 'to ${order.buyerName}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _row('Quantity', '${order.quantity} ${order.unit}'),
          const SizedBox(height: 6),
          _row('Price / ${order.unit}', order.pricePerUnit.kes),
          const SizedBox(height: 6),
          _row(
            'Total',
            (order.quantity * order.pricePerUnit).kes,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final OrderModel order;
  const _RouteCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final distance = TransportEstimator.distanceKm(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
    );
    final cost = TransportEstimator.costKes(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
      quantityTonnes: order.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _endpoint(
            icon: Icons.agriculture_outlined,
            color: AppColors.primary,
            label: 'Pickup',
            location: order.pickupBroadLocation,
            county: order.pickupCounty,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 18),
            child: SizedBox(
              width: 2,
              height: 22,
              child: ColoredBox(color: AppColors.border),
            ),
          ),
          _endpoint(
            icon: Icons.location_on,
            color: AppColors.secondary,
            label: 'Delivery',
            location: order.deliveryBroadLocation,
            county: order.deliveryCounty,
          ),
          if (order.deliveryNotes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryNotes!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (distance > 0) ...[
            const Divider(height: 24, color: AppColors.border),
            Row(
              children: [
                const Icon(Icons.route_outlined,
                    size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  '≈ ${distance.toStringAsFixed(0)} km',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Est. transport',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      cost.kes,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Straight-line estimate. Final rate confirmed by Admin-assigned transporter.',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _endpoint({
    required IconData icon,
    required Color color,
    required String label,
    required String location,
    required String county,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
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
                    color: color),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                county,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogisticsCard extends StatelessWidget {
  final OrderModel order;
  const _LogisticsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = order.logisticsState;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined,
              color: AppColors.info, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin-mediated pickup',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  state?.label ?? 'Not yet scheduled',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final OrderModel order;
  final bool isBuyer;
  const _ActionButton({required this.order, required this.isBuyer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _labelFor(order.state, isBuyer);
    if (label == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () => _handleTap(context, ref),
      child: Text(label),
    );
  }

  String? _labelFor(OrderState state, bool isBuyer) {
    if (state.isTerminal) return null;
    switch (state) {
      case OrderState.negotiation:
        return isBuyer ? null : 'Accept offer';
      case OrderState.accepted:
        return isBuyer ? 'Secure payment' : null;
      case OrderState.paymentSecured:
        return 'Simulate Admin assignment';
      case OrderState.pickupScheduled:
        return 'Mark delivered';
      case OrderState.qualityConfirmed:
        return isBuyer ? 'Confirm quality & complete' : null;
      case OrderState.completed:
        return 'Release payment';
      case OrderState.paymentReleased:
        return 'Rate transaction';
      case OrderState.requested:
        return isBuyer ? null : 'Start negotiation';
      default:
        return null;
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final controller = ref.read(ordersControllerProvider);

    if (order.state == OrderState.paymentReleased) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RateOrderScreen(orderId: order.id),
        ),
      );
      return;
    }

    controller.advance(order.id);
  }
}
