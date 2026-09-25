import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/verification_request_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/segmented_toggle.dart';
import '../../shared/widgets/verification_badge.dart';
import 'controllers/admin_controller.dart';

class VerificationQueueScreen extends ConsumerStatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  ConsumerState<VerificationQueueScreen> createState() =>
      _VerificationQueueScreenState();
}

class _VerificationQueueScreenState
    extends ConsumerState<VerificationQueueScreen> {
  VerificationType? _filter;

  static const _filters = ['All', 'Vets', 'Companies', 'Vehicles'];

  VerificationType? _typeForIndex(int i) => switch (i) {
        0 => null,
        1 => VerificationType.vet,
        2 => VerificationType.company,
        _ => VerificationType.vehicle,
      };

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(pendingVerificationsProvider(_filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedToggle(
            options: _filters,
            selectedIndex: _filter == null
                ? 0
                : _filters.indexOf(_filter == VerificationType.vet
                    ? 'Vets'
                    : _filter == VerificationType.company
                        ? 'Companies'
                        : 'Vehicles'),
            onChanged: (i) => setState(() => _filter = _typeForIndex(i)),
            expand: false,
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No pending verifications',
                  subtitle: 'You are all caught up.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RequestCard(request: list[i]),
                ),
        ),
      ],
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final VerificationRequestModel request;
  const _RequestCard({required this.request});

  IconData get _icon => switch (request.type) {
        VerificationType.vet => Icons.medical_services_outlined,
        VerificationType.company => Icons.business,
        VerificationType.vehicle => Icons.local_shipping_outlined,
      };

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null) return;
    final admin = ref.read(authProvider);
    ref.read(adminControllerProvider).reject(
          request.id,
          admin?.name ?? 'Admin',
          reason,
        );
    if (!context.mounted) return;
    context.showSnack('Rejected ${request.applicantName}');
  }

  void _approve(BuildContext context, WidgetRef ref) {
    final admin = ref.read(authProvider);
    ref.read(adminControllerProvider).approve(
          request.id,
          admin?.name ?? 'Admin',
        );
    context.showSnack('Approved ${request.applicantName}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Row(
            children: [
              Icon(_icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.applicantName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              VerificationBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 10),
          _line('Type', request.type.label),
          const SizedBox(height: 4),
          if (request.type == VerificationType.vehicle) ...[
            _line('Plate', request.plateNumber ?? '—'),
            if (request.extraInfo != null) ...[
              const SizedBox(height: 4),
              _line('Vehicle', request.extraInfo!),
            ],
          ] else
            _line('Document', request.documentRef),
          const SizedBox(height: 4),
          _line('County', request.county),
          const SizedBox(height: 4),
          _line('Submitted', request.submittedAt.relative),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approve(context, ref),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
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
          hintText: 'e.g. Logbook QR did not match portal record',
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
