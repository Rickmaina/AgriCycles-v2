import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../controllers/dispute_controller.dart';

class RaiseDisputeScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const RaiseDisputeScreen({super.key, required this.order});

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _affectedQty = TextEditingController();
  final _affectedAmount = TextEditingController();

  DisputeIssueType _issueType = DisputeIssueType.quality;

  static const _issueTypes = [
    DisputeIssueType.quality,
    DisputeIssueType.quantity,
    DisputeIssueType.payment,
    DisputeIssueType.pickup,
    DisputeIssueType.other,
  ];

  @override
  void dispose() {
    _description.dispose();
    _affectedQty.dispose();
    _affectedAmount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    final qty = double.tryParse(_affectedQty.text.trim());
    final amount = double.tryParse(_affectedAmount.text.trim());

    ref.read(disputeControllerProvider).raise(
          order: widget.order,
          raisedById: user.id,
          raisedByName: user.name,
          issueType: _issueType,
          description: _description.text.trim(),
          affectedQuantity: qty,
          affectedAmount: amount,
        );

    context.showSnack('Dispute raised — Admin notified');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Raise dispute')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.resourceType,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.id.substring(3)}  •  ${order.quantity} ${order.unit}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (order.quantity * order.pricePerUnit).kes,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Label('What went wrong?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _issueTypes.map((t) {
                  final active = _issueType == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: active,
                    onSelected: (_) => setState(() => _issueType = t),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const _Label('Describe the issue'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What happened, when, and what outcome you expect.',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'At least 10 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              const _Label('Affected scope (optional)'),
              const SizedBox(height: 6),
              const Text(
                'Leave blank for a full-order dispute.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _affectedQty,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration:
                          InputDecoration(labelText: 'Qty (${order.unit})'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.positiveNumber(v, label: 'Quantity');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _affectedAmount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'KES ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.positiveNumber(v, label: 'Amount');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raising a dispute pauses this order. Admin reviews both sides before deciding.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Submit dispute'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
