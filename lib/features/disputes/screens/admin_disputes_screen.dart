import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/dispute_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../admin/widgets/admin_queue_card.dart';
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

  Color _statusColor(RoleTheme theme) {
    switch (dispute.status) {
      case DisputeStatus.open:
        return theme.accent;
      case DisputeStatus.underReview:
        return theme.primary;
      case DisputeStatus.resolved:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.admin;

    final amountLine = dispute.affectedAmount != null
        ? dispute.affectedAmount!.kes
        : 'Full order';

    return AdminQueueCard(
      theme: theme,
      icon: Icons.gavel_outlined,
      title: dispute.orderResourceType,
      statusChip: AdminStatusChip(
        label: dispute.status.label,
        color: _statusColor(theme),
      ),
      meta:
          '${dispute.issueType.label} • ${dispute.raisedByName} (${dispute.raisedByRole})',
      description: dispute.description,
      trailingText: '$amountLine  •  ${dispute.createdAt.relative}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DisputeDetailScreen(disputeId: dispute.id),
        ),
      ),
    );
  }
}
