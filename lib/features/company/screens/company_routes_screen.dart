import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/transport_estimator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../orders/controllers/orders_controller.dart';

/// Consolidated view of every active pickup route for this company.
/// Orders are grouped by pickup county and ordered by pickup sequence
/// so the company can see the full run at a glance.
class CompanyRoutesScreen extends ConsumerWidget {
  const CompanyRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final buying = ref.watch(buyingOrdersProvider(user.id));
    final active = buying.where((o) => !o.state.isTerminal).toList();

    if (active.isEmpty) {
      return const EmptyState(
        icon: Icons.map_outlined,
        title: 'No active pickups',
        subtitle: 'Once orders progress to pickup, the route appears here.',
      );
    }

    final grouped = <String, List<OrderModel>>{};
    for (final o in active) {
      grouped.putIfAbsent(o.pickupCounty, () => []).add(o);
    }

    var totalKm = 0.0;
    for (final o in active) {
      totalKm += TransportEstimator.distanceKm(
        pickupCounty: o.pickupCounty,
        deliveryCounty: o.deliveryCounty,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBanner(
          orderCount: active.length,
          totalKm: totalKm,
        ),
        const SizedBox(height: 16),
        for (final entry in grouped.entries) ...[
          _CountyHeader(
            county: entry.key,
            count: entry.value.length,
          ),
          const SizedBox(height: 8),
          ...entry.value.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RouteStop(order: o),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int orderCount;
  final double totalKm;
  const _SummaryBanner({
    required this.orderCount,
    required this.totalKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, size: 32, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$orderCount active pickup${orderCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total straight-line run: ≈ ${totalKm.toStringAsFixed(0)} km',
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

class _CountyHeader extends StatelessWidget {
  final String county;
  final int count;

  const _CountyHeader({required this.county, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            county,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
          Text(
            '($count stop${count == 1 ? '' : 's'})',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final OrderModel order;
  const _RouteStop({required this.order});

  @override
  Widget build(BuildContext context) {
    final km = TransportEstimator.distanceKm(
      pickupCounty: order.pickupCounty,
      deliveryCounty: order.deliveryCounty,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.resourceType,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${order.quantity} ${order.unit}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 26,
                    color: AppColors.border,
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup: ${order.pickupBroadLocation}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Deliver: ${order.deliveryBroadLocation}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '${km.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'from ${order.sellerName}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                order.state.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: order.state == OrderState.paymentSecured
                      ? AppColors.info
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
