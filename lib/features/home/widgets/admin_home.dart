import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/kpi_strip.dart';
import '../../../shared/widgets/priority_row.dart';
import '../../../shared/widgets/section_header.dart';
import '../../disputes/controllers/dispute_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../admin/controllers/admin_controller.dart';

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    const theme = RoleTheme.admin;
    final pendingVerifications = ref.watch(pendingVerificationsProvider(null));
    final logistics = ref.watch(logisticsQueueProvider);
    final disputes = ref.watch(openDisputesProvider);
    final awaitingAssignment = logistics
        .where(
            (o) => o.logisticsState == LogisticsState.awaitingAdminAssignment)
        .length;
    final openDisputeCount =
        disputes.where((d) => d.status == DisputeStatus.open).length;

    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          KpiStrip(
            theme: theme,
            items: [
              KpiItem(
                icon: Icons.verified_user_outlined,
                label: 'To verify',
                value: '${pendingVerifications.length}',
                tone: pendingVerifications.isNotEmpty
                    ? KpiTone.warning
                    : KpiTone.normal,
              ),
              KpiItem(
                icon: Icons.local_shipping_outlined,
                label: 'Awaiting pickup',
                value: '$awaitingAssignment',
                tone:
                    awaitingAssignment > 0 ? KpiTone.attention : KpiTone.normal,
              ),
              KpiItem(
                icon: Icons.gavel_outlined,
                label: 'Open disputes',
                value: '$openDisputeCount',
                tone: openDisputeCount > 0 ? KpiTone.danger : KpiTone.normal,
              ),
              KpiItem(
                icon: Icons.pending_actions_outlined,
                label: 'Total queue',
                value:
                    '${pendingVerifications.length + awaitingAssignment + openDisputeCount}',
                tone: KpiTone.emphasis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionHeader(
            theme: theme,
            icon: Icons.priority_high,
            title: 'Action queue',
            badge: _totalActionable(
              pendingVerifications.length,
              awaitingAssignment,
              openDisputeCount,
            ),
          ),
          if (pendingVerifications.isEmpty &&
              awaitingAssignment == 0 &&
              openDisputeCount == 0)
            const _AllClear(theme: theme)
          else
            Column(
              children: [
                if (openDisputeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PriorityRow(
                      theme: theme,
                      icon: Icons.gavel_outlined,
                      title: 'Disputes awaiting review',
                      subtitle:
                          '$openDisputeCount need${openDisputeCount == 1 ? "s" : ""} a decision',
                      trailingValue: '$openDisputeCount',
                      tone: PriorityTone.urgent,
                    ),
                  ),
                if (awaitingAssignment > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PriorityRow(
                      theme: theme,
                      icon: Icons.local_shipping_outlined,
                      title: 'Pickups awaiting assignment',
                      subtitle:
                          '$awaitingAssignment order${awaitingAssignment == 1 ? "" : "s"} need a transporter',
                      trailingValue: '$awaitingAssignment',
                      tone: PriorityTone.attention,
                    ),
                  ),
                if (pendingVerifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PriorityRow(
                      theme: theme,
                      icon: Icons.verified_user_outlined,
                      title: 'Verification queue',
                      subtitle: _verificationBreakdown(pendingVerifications),
                      trailingValue: '${pendingVerifications.length}',
                      tone: PriorityTone.info,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          const SectionHeader(
            theme: theme,
            icon: Icons.insights_outlined,
            title: 'Snapshot',
          ),
          const _SnapshotCard(theme: theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String? _totalActionable(int v, int l, int d) {
    final n = v + l + d;
    return n == 0 ? null : '$n';
  }

  String _verificationBreakdown(List<dynamic> list) {
    final vets = list.where((r) => r.type == VerificationType.vet).length;
    final companies =
        list.where((r) => r.type == VerificationType.company).length;
    final vehicles =
        list.where((r) => r.type == VerificationType.vehicle).length;
    final parts = <String>[];
    if (vets > 0) parts.add('$vets vet${vets == 1 ? "" : "s"}');
    if (companies > 0) {
      parts.add('$companies compan${companies == 1 ? "y" : "ies"}');
    }
    if (vehicles > 0) {
      parts.add('$vehicles vehicle${vehicles == 1 ? "" : "s"}');
    }
    return parts.isEmpty ? 'Nothing pending' : parts.join(' • ');
  }
}

class _AllClear extends StatelessWidget {
  final RoleTheme theme;
  const _AllClear({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle_outline,
                color: theme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No disputes, pickups, or verifications waiting.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final RoleTheme theme;
  const _SnapshotCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          _row(
            'Total listings',
            '6',
            theme,
          ),
          Divider(height: 20, color: theme.border),
          _row(
            'Orders this week',
            '4',
            theme,
          ),
          Divider(height: 20, color: theme.border),
          _row(
            'Community orders active',
            '2',
            theme,
          ),
          Divider(height: 20, color: theme.border),
          _row(
            'Pending verifications',
            '3',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, RoleTheme theme) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }
}
