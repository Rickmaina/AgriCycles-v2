import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/role_theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/order_model.dart';
import '../../domain/transport_estimator.dart';
import '../../shared/widgets/empty_state.dart';
import '../orders/controllers/orders_controller.dart';
import 'widgets/admin_queue_card.dart';

class LogisticsQueueScreen extends ConsumerWidget {
  const LogisticsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(logisticsQueueProvider);

    if (queue.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No pickups waiting',
        subtitle: 'Orders appear here after payment is secured.',
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _NtsaNote(),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: queue.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LogisticsCard(order: queue[i]),
          ),
        ),
      ],
    );
  }
}

class _LogisticsCard extends ConsumerWidget {
  final OrderModel order;
  const _LogisticsCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.admin;
    final waiting =
        order.logisticsState == LogisticsState.awaitingAdminAssignment;

    final lines = <AdminQueueLine>[
      AdminQueueLine('Seller', order.sellerName),
      AdminQueueLine('Buyer', order.buyerName),
      AdminQueueLine('Pickup', order.pickupBroadLocation),
      AdminQueueLine('Delivery', order.deliveryBroadLocation),
      AdminQueueLine('Load', '${order.quantity} ${order.unit}'),
      if (TransportEstimator.distanceKm(
            pickupCounty: order.pickupCounty,
            deliveryCounty: order.deliveryCounty,
          ) >
          0)
        AdminQueueLine('Distance', _distanceLine()),
    ];

    return AdminQueueCard(
      theme: theme,
      icon: Icons.local_shipping_outlined,
      title: order.resourceType,
      statusChip: _LogiChip(state: order.logisticsState),
      lines: lines,
      actions: [
        if (waiting)
          ElevatedButton.icon(
            onPressed: () => _onAssign(context, ref),
            icon: const Icon(Icons.local_shipping, size: 18),
            label: const Text('Assign pickup'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _onDelivered(context, ref),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark delivered'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
      ],
    );
  }

  String _distanceLine() {
    final km = TransportEstimator.distanceKm(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
    );
    final cost = TransportEstimator.costKes(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
      quantityTonnes: order.quantity,
    );
    return '≈ ${km.toStringAsFixed(0)} km  •  ${cost.kes} est.';
  }

  void _onAssign(BuildContext context, WidgetRef ref) {
    ref.read(ordersControllerProvider).advance(order.id);
    context.showSnack('Pickup assigned');
  }

  void _onDelivered(BuildContext context, WidgetRef ref) {
    ref.read(ordersControllerProvider).advance(order.id);
    context.showSnack('Marked delivered');
  }
}

class _NtsaNote extends StatelessWidget {
  const _NtsaNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.info),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assign only NTSA-verified vehicles. Check the Verify tab first.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogiChip extends StatelessWidget {
  final LogisticsState? state;
  const _LogiChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      LogisticsState.awaitingAdminAssignment => (
          'Awaiting assignment',
          AppColors.warning
        ),
      LogisticsState.pickupAssigned => ('Assigned', AppColors.info),
      LogisticsState.inTransit => ('In transit', AppColors.info),
      LogisticsState.delivered => ('Delivered', AppColors.success),
      null => ('—', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
