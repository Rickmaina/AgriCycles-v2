import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/pre_order_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/pre_order_controller.dart';
import 'community_order_detail_screen.dart';

class CommunityOrdersListScreen extends ConsumerWidget {
  const CommunityOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openPreOrdersProvider);

    if (open.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No open community orders',
        subtitle: 'Buyers will publish aggregation requests here as they post.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: open.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PreOrderCard(preOrder: open[i]),
    );
  }
}

class _PreOrderCard extends ConsumerWidget {
  final PreOrderModel preOrder;
  const _PreOrderCard({required this.preOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(preOrderControllerProvider);
    final committed = controller.totalCommitted(preOrder.id);
    final progress = preOrder.targetQuantity <= 0
        ? 0.0
        : (committed / preOrder.targetQuantity).clamp(0.0, 1.0);
    final daysLeft = preOrder.deadline.difference(DateTime.now()).inDays;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CommunityOrderDetailScreen(preOrderId: preOrder.id),
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
                      preOrder.resourceType,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'from ${preOrder.buyerName}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${committed.toStringAsFixed(1)} / ${preOrder.targetQuantity} ${preOrder.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      preOrder.deliveryBroadLocation,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${preOrder.offeredPricePerUnit.kes} / ${preOrder.unit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    daysLeft <= 3 ? Icons.schedule : Icons.event_outlined,
                    size: 14,
                    color:
                        daysLeft <= 3 ? AppColors.warning : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysLeft <= 0
                        ? 'Deadline passed'
                        : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysLeft <= 3
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
