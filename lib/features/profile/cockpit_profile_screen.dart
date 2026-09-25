import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/verification_badge.dart';

class CockpitProfileScreen extends ConsumerWidget {
  const CockpitProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _IdentityCard(
          name: user.name,
          roleLabel: user.role.label,
          verificationStatus: user.verificationStatus,
        ),
        const SizedBox(height: 20),
        _Group(
          title: 'Contact',
          rows: [
            _RowData(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone.maskedPhone,
            ),
            if (user.email != null)
              _RowData(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _Group(
          title: 'Farm & location',
          rows: [
            _RowData(
              icon: Icons.agriculture_outlined,
              label: 'Farmer type',
              value: user.farmerType?.label ?? 'Not set',
            ),
            if (user.cropDetails != null)
              _RowData(
                icon: Icons.grass_outlined,
                label: 'Crops',
                value: user.cropDetails!,
              ),
            _RowData(
              icon: Icons.location_on_outlined,
              label: 'County',
              value: user.county ?? '—',
            ),
            _RowData(
              icon: Icons.map_outlined,
              label: 'Sub-county',
              value: user.subCounty ?? '—',
            ),
            _RowData(
              icon: Icons.home_outlined,
              label: 'Area',
              value: user.area ?? '—',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Group(
          title: 'Privacy',
          rows: [
            _RowData(
              icon: Icons.visibility_off_outlined,
              label: 'Contact visibility',
              value: 'Shared only after order acceptance',
            ),
            _RowData(
              icon: Icons.security_outlined,
              label: 'Data',
              value: 'Encrypted at rest and in transit',
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            context.go(AppRoutes.login);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final VerificationStatus verificationStatus;

  const _IdentityCard({
    required this.name,
    required this.roleLabel,
    required this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.initials,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            roleLabel,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          VerificationBadge(status: verificationStatus),
        ],
      ),
    );
  }
}

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  const _RowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _Group extends StatelessWidget {
  final String title;
  final List<_RowData> rows;
  const _Group({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _Row(row: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final _RowData row;
  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(row.icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Flexible(
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
