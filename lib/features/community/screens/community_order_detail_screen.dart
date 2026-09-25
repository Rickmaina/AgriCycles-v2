import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/kenya_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/community_contribution_model.dart';
import '../../../data/models/pre_order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../controllers/pre_order_controller.dart';

class CommunityOrderDetailScreen extends ConsumerWidget {
  final String preOrderId;
  const CommunityOrderDetailScreen({super.key, required this.preOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preOrder = ref.watch(preOrderByIdProvider(preOrderId));
    final user = ref.watch(authProvider);

    if (preOrder == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Community order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isBuyer = preOrder.buyerId == user.id;
    final contributions = ref.watch(contributionsForProvider(preOrderId));
    final controller = ref.read(preOrderControllerProvider);
    final committed = controller.totalCommitted(preOrderId);
    final progress = preOrder.targetQuantity <= 0
        ? 0.0
        : (committed / preOrder.targetQuantity).clamp(0.0, 1.0);
    final locked = preOrder.status != PreOrderStatus.open;

    return Scaffold(
      appBar: AppBar(title: const Text('Community order')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SummaryCard(
            preOrder: preOrder,
            committed: committed,
            progress: progress,
          ),
          const SizedBox(height: 20),

          if (isBuyer && contributions.isNotEmpty) ...[
            const _SectionLabel('Contributions & route'),
            const SizedBox(height: 10),
            _RouteCard(
              contributions: contributions,
              unit: preOrder.unit,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Review contributions (${contributions.length})'),
            const SizedBox(height: 10),
            ...contributions.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContributionCard(
                  contribution: c,
                  unit: preOrder.unit,
                  canReview:
                      c.status == ContributionStatus.committed,
                ),
              ),
            ),
          ] else if (!isBuyer && !locked) ...[
            const _SectionLabel('Commit your quantity'),
            const SizedBox(height: 10),
            _ContributeForm(
              preOrder: preOrder,
              remaining:
                  (preOrder.targetQuantity - committed).clamp(0, double.infinity),
            ),
          ] else if (!isBuyer && locked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 18, color: AppColors.info),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Target reached — contributions are closed.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isBuyer && contributions.isEmpty) ...[
            const _SectionLabel('Contributions'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty,
                      color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No contributions yet. Eligible farmers have been notified.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PreOrderModel preOrder;
  final double committed;
  final double progress;

  const _SummaryCard({
    required this.preOrder,
    required this.committed,
    required this.progress,
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  preOrder.resourceType,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(preOrder.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'from ${preOrder.buyerName}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${committed.toStringAsFixed(1)} / ${preOrder.targetQuantity} ${preOrder.unit}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          _row('Price per ${preOrder.unit}',
              preOrder.offeredPricePerUnit.kes),
          const SizedBox(height: 6),
          _row('Total budget', preOrder.totalBudget.kes, bold: true),
          const SizedBox(height: 6),
          _row('Deliver to', preOrder.deliveryBroadLocation),
          const SizedBox(height: 6),
          _row('Deadline', preOrder.deadline.shortDate),
          if (preOrder.description != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                preOrder.description!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
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

  Widget _statusChip(PreOrderStatus status) {
    final color = switch (status) {
      PreOrderStatus.open => AppColors.statePending,
      PreOrderStatus.locked => AppColors.info,
      PreOrderStatus.completed => AppColors.success,
      PreOrderStatus.cancelled => AppColors.danger,
      PreOrderStatus.expired => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final List<CommunityContributionModel> contributions;
  final String unit;

  const _RouteCard({required this.contributions, required this.unit});

  @override
  Widget build(BuildContext context) {
    final confirmed = contributions
        .where((c) => c.status == ContributionStatus.confirmed)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.info.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, size: 18, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Pickup route across farms',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (confirmed.isEmpty)
            const Text(
              'Confirm contributions to see the route.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ...List.generate(confirmed.length, (i) {
              final c = confirmed[i];
              final last = i == confirmed.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                        if (!last)
                          Container(
                            width: 2,
                            height: 22,
                            color:
                                AppColors.info.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.farmerName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              c.pickupBroadLocation,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            Text(
                              '${c.effectiveQuantity} $unit',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ContributionCard extends ConsumerWidget {
  final CommunityContributionModel contribution;
  final String unit;
  final bool canReview;

  const _ContributionCard({
    required this.contribution,
    required this.unit,
    required this.canReview,
  });

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
        text: contribution.committedQuantity.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm quantity'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
              labelText: 'Accepted quantity ($unit)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, double.tryParse(controller.text.trim())),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (value == null || value <= 0) return;
    ref.read(preOrderControllerProvider).acceptContribution(
          contribution.id,
          acceptedQuantity: value,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  contribution.farmerName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(contribution.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Committed: ${contribution.committedQuantity} $unit',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          if (contribution.acceptedQuantity != null) ...[
            const SizedBox(height: 2),
            Text(
              'Accepted: ${contribution.acceptedQuantity} $unit',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Pickup: ${contribution.pickupBroadLocation}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          if (canReview) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(preOrderControllerProvider)
                        .rejectContribution(contribution.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _accept(context, ref),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(ContributionStatus status) {
    final color = switch (status) {
      ContributionStatus.committed => AppColors.statePending,
      ContributionStatus.confirmed => AppColors.success,
      ContributionStatus.rejected => AppColors.danger,
      ContributionStatus.withdrawn => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ContributeForm extends ConsumerStatefulWidget {
  final PreOrderModel preOrder;
  final double remaining;

  const _ContributeForm({
    required this.preOrder,
    required this.remaining,
  });

  @override
  ConsumerState<_ContributeForm> createState() => _ContributeFormState();
}

class _ContributeFormState extends ConsumerState<_ContributeForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _subCounty = TextEditingController();
  final _area = TextEditingController();
  String? _county;

  @override
  void dispose() {
    _quantity.dispose();
    _subCounty.dispose();
    _area.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    ref.read(preOrderControllerProvider).contribute(
          preOrder: widget.preOrder,
          farmerId: user.id,
          farmerName: user.name,
          quantity: double.parse(_quantity.text.trim()),
          pickupCounty: _county!,
          pickupSubCounty: _subCounty.text.trim(),
          pickupArea: _area.text.trim(),
        );

    context.showSnack('Contribution submitted');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.remaining.toStringAsFixed(1)} ${widget.preOrder.unit} still needed',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantity,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
                labelText: 'Your quantity (${widget.preOrder.unit})'),
            validator: (v) =>
                Validators.positiveNumber(v, label: 'Quantity'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your pickup point',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _county,
            decoration: const InputDecoration(labelText: 'County'),
            items: KenyaLocations.counties
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _county = v),
            validator: Validators.county,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subCounty,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Sub-county'),
            validator: (v) =>
                Validators.requiredText(v, label: 'Sub-county'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _area,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(labelText: 'Area / Village'),
            validator: (v) =>
                Validators.requiredText(v, label: 'Area'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Commit quantity'),
          ),
        ],
      ),
    );
  }
}
