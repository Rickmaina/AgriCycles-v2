import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/dispute_model.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/dispute_controller.dart';

class DisputeDetailScreen extends ConsumerWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispute = ref.watch(disputeByIdProvider(disputeId));
    final user = ref.watch(authProvider);

    if (dispute == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute')),
        body: const Center(child: Text('Dispute not found')),
      );
    }

    final isAdmin = user.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Dispute')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _StatusHeader(dispute: dispute),
          const SizedBox(height: 16),
          _DetailsCard(dispute: dispute),
          const SizedBox(height: 16),
          if (dispute.status == DisputeStatus.resolved) ...[
            _ResolutionCard(dispute: dispute),
            const SizedBox(height: 16),
          ],
          if (isAdmin && dispute.status != DisputeStatus.resolved) ...[
            _AdminActions(dispute: dispute),
          ],
          if (!isAdmin) ...[
            const SizedBox(height: 8),
            const Text(
              'Admin reviews both sides and decides the outcome. You will be notified when resolved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final DisputeModel dispute;
  const _StatusHeader({required this.dispute});

  @override
  Widget build(BuildContext context) {
    final color = switch (dispute.status) {
      DisputeStatus.open => AppColors.statePending,
      DisputeStatus.underReview => AppColors.info,
      DisputeStatus.resolved => AppColors.success,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            dispute.status == DisputeStatus.resolved
                ? Icons.check_circle
                : Icons.gavel,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispute.issueType.label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  dispute.status.label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final DisputeModel dispute;
  const _DetailsCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
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
          _row('Order', dispute.orderResourceType),
          const SizedBox(height: 6),
          _row(
              'Raised by', '${dispute.raisedByName} (${dispute.raisedByRole})'),
          const SizedBox(height: 6),
          _row('Raised', dispute.createdAt.relative),
          if (dispute.affectedQuantity != null) ...[
            const SizedBox(height: 6),
            _row('Affected qty', dispute.affectedQuantity!.toStringAsFixed(1)),
          ],
          if (dispute.affectedAmount != null) ...[
            const SizedBox(height: 6),
            _row('Affected amount', dispute.affectedAmount!.kes),
          ],
          const Divider(height: 24, color: AppColors.border),
          const Text(
            'Description',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            dispute.description,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  final DisputeModel dispute;
  const _ResolutionCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Resolution',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dispute.resolution?.label ?? 'Resolved',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.success),
          ),
          if (dispute.resolutionNotes != null) ...[
            const SizedBox(height: 6),
            Text(
              dispute.resolutionNotes!,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Resolved by ${dispute.resolvedBy ?? "Admin"} • ${dispute.resolvedAt?.relative ?? ""}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AdminActions extends ConsumerWidget {
  final DisputeModel dispute;
  const _AdminActions({required this.dispute});

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    DisputeResolution resolution,
  ) async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Resolve: ${resolution.label}'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Context for the decision',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final admin = ref.read(authProvider);
    ref.read(disputeControllerProvider).resolve(
          disputeId: dispute.id,
          resolution: resolution,
          adminName: admin?.name ?? 'Admin',
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        );
    context.showSnack('Dispute resolved');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final underReview = dispute.status == DisputeStatus.underReview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!underReview)
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(disputeControllerProvider).markUnderReview(dispute.id),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Mark under review'),
          ),
        if (!underReview) const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _resolve(
            context,
            ref,
            DisputeResolution.favourBuyer,
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Refund buyer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _resolve(
            context,
            ref,
            DisputeResolution.favourSeller,
          ),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Release to seller'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _resolve(
            context,
            ref,
            DisputeResolution.split,
          ),
          icon: const Icon(Icons.call_split),
          label: const Text('Split'),
        ),
      ],
    );
  }
}
