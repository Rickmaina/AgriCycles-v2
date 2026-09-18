import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/dispute_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/dispute_controller.dart';
import 'dispute_detail_screen.dart';

class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openDisputesProvider);

    if (open.isEmpty) {
      return const EmptyState(
        icon: Icons.gavel_outlined,
        title: 'No open disputes',
        subtitle: 'You are all caught up.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: open.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _DisputeCard(dispute: open[i]),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final DisputeModel dispute;
  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    final color = switch (dispute.status) {
      DisputeStatus.open => AppColors.statePending,
      DisputeStatus.underReview => AppColors.info,
      DisputeStatus.resolved => AppColors.success,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DisputeDetailScreen(disputeId: dispute.id),
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
                      dispute.orderResourceType,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dispute.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${dispute.issueType.label} • ${dispute.raisedByName} (${dispute.raisedByRole})',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                dispute.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (dispute.affectedAmount != null)
                    Text(
                      dispute.affectedAmount!.kes,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Text(
                      'Full order',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  const Spacer(),
                  Text(
                    dispute.createdAt.relative,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 6),
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
