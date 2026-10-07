import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/role_theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/payment_verification_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/payment_verification_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../orders/controllers/orders_controller.dart';
import 'document_viewer_screen.dart';
import 'widgets/admin_queue_card.dart';

class PaymentQueueScreen extends ConsumerWidget {
  const PaymentQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pendingPaymentsProvider);

    return list.isEmpty
        ? const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payments to verify',
            subtitle: 'Submitted payment evidence appears here.',
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PaymentCard(payment: list[i]),
          );
  }
}

class _PaymentCard extends ConsumerWidget {
  final PaymentVerificationModel payment;
  const _PaymentCard({required this.payment});

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null) return;
    final admin = ref.read(authProvider);
    ref
        .read(paymentVerificationProvider.notifier)
        .reject(payment.id, admin?.name ?? 'Admin', reason);
    if (!context.mounted) return;
    context.showSnack('Rejected payment for ${payment.orderId}');
  }

  void _verify(BuildContext context, WidgetRef ref) {
    final admin = ref.read(authProvider);
    ref
        .read(paymentVerificationProvider.notifier)
        .verify(payment.id, admin?.name ?? 'Admin');
    ref.read(ordersControllerProvider).advance(payment.orderId);
    context.showSnack('Verified ${payment.reference}');
  }

  void _openScreenshot(BuildContext context) {
    if (payment.screenshotRef == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          title: 'Screenshot · ${payment.reference}',
          refs: [payment.screenshotRef!],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.admin;

    final lines = <AdminQueueLine>[
      AdminQueueLine('Order', payment.orderId),
      AdminQueueLine('Resource', payment.resourceType),
      AdminQueueLine('Buyer', payment.buyerName),
      AdminQueueLine('Seller', payment.sellerName),
      AdminQueueLine('Method', payment.method.toUpperCase()),
      if (payment.payerName != null)
        AdminQueueLine('Payer', payment.payerName!),
      if (payment.payerAccount != null)
        AdminQueueLine('Account', payment.payerAccount!),
      if (payment.note != null && payment.note!.isNotEmpty)
        AdminQueueLine('Note', payment.note!),
    ];

    return AdminQueueCard(
      theme: theme,
      icon: Icons.payments_outlined,
      title: payment.amount.kes,
      statusChip: AdminStatusChip(
        label: payment.submittedAt.relative,
        color: theme.accent,
      ),
      meta: 'Ref ${payment.reference}',
      lines: lines,
      actions: [
        if (payment.screenshotRef != null)
          OutlinedButton(
            onPressed: () => _openScreenshot(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Receipt'),
          ),
        OutlinedButton(
          onPressed: () => _reject(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.danger,
            side: BorderSide(color: theme.danger),
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () => _verify(context, ref),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reason for rejection'),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'e.g. Reference not found in M-Pesa statement',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final t = _ctrl.text.trim();
            Navigator.pop(context, t.isEmpty ? 'No reason given' : t);
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
