import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/order_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/segmented_toggle.dart';
import 'controllers/orders_controller.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  int _tab = 0;

  static const _tabs = ['Buying', 'Selling'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final orders = _tab == 0
        ? ref.watch(buyingOrdersProvider(user.id))
        : ref.watch(sellingOrdersProvider(user.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedToggle(
            options: _tabs,
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: _tab == 0 ? 'No purchase orders yet' : 'No sales yet',
                  subtitle: _tab == 0
                      ? 'Browse the market and make an offer to get started.'
                      : 'Your listings will show orders here once buyers engage.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OrderCard(
                    order: orders[i],
                    isBuying: _tab == 0,
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isBuying;

  const _OrderCard({required this.order, required this.isBuying});

  @override
  Widget build(BuildContext context) {
    final counterparty = isBuying ? order.sellerName : order.buyerName;
    final counterpartyLabel = isBuying ? 'from' : 'to';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
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
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StateChip(state: order.state),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$counterpartyLabel $counterparty',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.pickupBroadLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    '${order.quantity} ${order.unit}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    (order.quantity * order.pricePerUnit).kes,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final OrderState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _colorFor(OrderState s) {
    switch (s) {
      case OrderState.requested:
        return AppColors.statePending;
      case OrderState.negotiation:
        return AppColors.stateActive;
      case OrderState.accepted:
        return AppColors.info;
      case OrderState.paymentSecured:
        return AppColors.stateSecured;
      case OrderState.pickupScheduled:
        return AppColors.stateActive;
      case OrderState.qualityConfirmed:
        return AppColors.stateActive;
      case OrderState.completed:
      case OrderState.paymentReleased:
      case OrderState.rated:
        return AppColors.stateCompleted;
      case OrderState.declined:
      case OrderState.disputed:
        return AppColors.stateDisputed;
      case OrderState.expired:
        return AppColors.stateExpired;
    }
  }
}
