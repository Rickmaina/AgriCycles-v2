import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/verification_request_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/segmented_toggle.dart';
import '../../shared/widgets/verification_badge.dart';
import 'controllers/admin_controller.dart';
import 'document_viewer_screen.dart';
import 'widgets/admin_queue_card.dart';

/// Top-level queue groups shown in the primary filter row.
enum _Group { all, transport, business }

/// Sub-filter applied when a group has more than one type.
enum _Sub { all, drivers, vehicles, companies }

class VerificationQueueScreen extends ConsumerStatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  ConsumerState<VerificationQueueScreen> createState() =>
      _VerificationQueueScreenState();
}

class _VerificationQueueScreenState
    extends ConsumerState<VerificationQueueScreen> {
  _Group _group = _Group.all;
  _Sub _sub = _Sub.all;

  static const _groupLabels = ['All', 'Transport', 'Business'];
  static const _transportLabels = ['All', 'Drivers', 'Vehicles'];
  static const _businessLabels = ['Companies'];

  List<VerificationType>? get _typesFor {
    switch (_group) {
      case _Group.all:
        return null;
      case _Group.transport:
        switch (_sub) {
          case _Sub.drivers:
            return [VerificationType.driver];
          case _Sub.vehicles:
            return [VerificationType.vehicle];
          case _Sub.all:
          case _Sub.companies:
            return [VerificationType.driver, VerificationType.vehicle];
        }
      case _Group.business:
        return [VerificationType.company];
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(pendingVerificationsProvider(null));
    final types = _typesFor;
    final list = types == null
        ? all
        : all.where((r) => types.contains(r.type)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedToggle(
            options: _groupLabels,
            selectedIndex: _group.index,
            onChanged: (i) => setState(() {
              _group = _Group.values[i];
              _sub = _Sub.all;
            }),
            expand: false,
          ),
        ),
        if (_group == _Group.transport)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedToggle(
              options: _transportLabels,
              selectedIndex: _sub == _Sub.drivers
                  ? 1
                  : _sub == _Sub.vehicles
                      ? 2
                      : 0,
              onChanged: (i) => setState(() {
                _sub = i == 1
                    ? _Sub.drivers
                    : i == 2
                        ? _Sub.vehicles
                        : _Sub.all;
              }),
              expand: false,
            ),
          ),
        if (_group == _Group.business)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedToggle(
              options: _businessLabels,
              selectedIndex: 0,
              onChanged: (_) {},
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
        VerificationType.driver => Icons.badge_outlined,
      };

  List<AdminQueueLine> get _lines {
    switch (request.type) {
      case VerificationType.driver:
        return [
          if (request.driverLicence != null)
            AdminQueueLine('Licence', request.driverLicence!),
          if (request.driverVehiclePlate != null)
            AdminQueueLine('Vehicle', request.driverVehiclePlate!),
          if (request.driverVehicleClass != null)
            AdminQueueLine('Class', request.driverVehicleClass!),
          AdminQueueLine('County', request.county),
          AdminQueueLine('Submitted', request.submittedAt.relative),
        ];
      case VerificationType.vehicle:
        return [
          AdminQueueLine('Plate', request.plateNumber ?? '—'),
          if (request.extraInfo != null)
            AdminQueueLine('Vehicle', request.extraInfo!),
          AdminQueueLine('County', request.county),
          AdminQueueLine('Submitted', request.submittedAt.relative),
        ];
      case VerificationType.company:
        return [
          AdminQueueLine('County', request.county),
          AdminQueueLine('Submitted', request.submittedAt.relative),
        ];
      case VerificationType.vet:
        return [
          AdminQueueLine('County', request.county),
          AdminQueueLine('Submitted', request.submittedAt.relative),
        ];
    }
  }

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

  void _openDocs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          title: request.applicantName,
          refs: request.documentRefs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.admin;

    return AdminQueueCard(
      theme: theme,
      icon: _icon,
      title: request.applicantName,
      statusChip: VerificationBadge(status: request.status),
      lines: _lines,
      actions: [
        OutlinedButton(
          onPressed: () => _openDocs(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Docs'),
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
          onPressed: () => _approve(context, ref),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Approve'),
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
