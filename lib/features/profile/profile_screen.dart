import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_tile.dart';
import '../../shared/widgets/verification_badge.dart';

/// Role-aware profile.
///
/// Farmer: identity, phone, listings, help, logout (5 rows).
/// Company: business identity, verification status, license,
/// locations, help, logout (denser rows).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCompany = user.role == UserRole.company;
    return isCompany
        ? _CompanyProfile(user: user)
        : _FarmerProfile(user: user);
  }
}

// ─────────────────────────────────────────────────────────────
// Farmer profile
// ─────────────────────────────────────────────────────────────

class _FarmerProfile extends ConsumerWidget {
  final dynamic user;
  const _FarmerProfile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _identityCard(
              theme: theme,
              name: user.name as String,
              subtitle: _locationLine(
                user.area as String?,
                user.county as String?,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(
              theme: theme,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _maskPhone(user.phone as String),
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.inventory_2_outlined,
              title: 'My listings',
              subtitle: 'What you are selling',
              onTap: () => context.push(AppRoutes.myListings),
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'How to use the app',
              onTap: () => context.push(AppRoutes.help),
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.logout,
              title: 'Log out',
              subtitle: 'See you next time',
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Company profile
// ─────────────────────────────────────────────────────────────

class _CompanyProfile extends ConsumerWidget {
  final dynamic user;
  const _CompanyProfile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final verification =
        user.verificationStatus as VerificationStatus;

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _identityCard(
              theme: theme,
              name: user.name as String,
              subtitle: _locationLine(null, user.county as String?),
            ),
            const SizedBox(height: 16),
            _verificationBlock(theme, verification),
            const SizedBox(height: 20),
            _infoRow(
              theme: theme,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _maskPhone(user.phone as String),
            ),
            const SizedBox(height: 10),
            if (user.email != null) ...[
              _infoRow(
                theme: theme,
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email as String,
              ),
              const SizedBox(height: 10),
            ],
            _infoRow(
              theme: theme,
              icon: Icons.location_on_outlined,
              label: 'Operating base',
              value: (user.county as String?) ?? '—',
            ),
            const SizedBox(height: 20),
            FarmerTile(
              icon: Icons.assignment_outlined,
              title: 'My needs',
              subtitle: 'Buy requests you have posted',
              onTap: () => context.push(AppRoutes.browseNeeds),
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'How to use the app',
              onTap: () => context.push(AppRoutes.help),
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Language, notifications',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            FarmerTile(
              icon: Icons.logout,
              title: 'Log out',
              subtitle: 'See you next time',
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _verificationBlock(RoleTheme theme, VerificationStatus status) {
    final (label, color, icon, description) = _verificationDetails(
      theme,
      status,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          VerificationBadge(status: status),
        ],
      ),
    );
  }

  (String, Color, IconData, String) _verificationDetails(
    RoleTheme theme,
    VerificationStatus status,
  ) {
    switch (status) {
      case VerificationStatus.approved:
        return (
          'Verified company',
          theme.primary,
          Icons.verified,
          'Buyers and sellers see your verified badge.',
        );
      case VerificationStatus.pending:
        return (
          'Verification pending',
          theme.accent,
          Icons.schedule,
          'We are reviewing your documents.',
        );
      case VerificationStatus.rejected:
        return (
          'Verification rejected',
          theme.danger,
          Icons.cancel_outlined,
          'Contact support for details.',
        );
      case VerificationStatus.suspended:
        return (
          'Account suspended',
          theme.danger,
          Icons.block,
          'Contact support for details.',
        );
      case VerificationStatus.unverified:
        return (
          'Not yet verified',
          theme.textMuted,
          Icons.help_outline,
          'Submit business documents to get verified.',
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Shared components
// ─────────────────────────────────────────────────────────────

Widget _identityCard({
  required RoleTheme theme,
  required String name,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.border, width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
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

Widget _infoRow({
  required RoleTheme theme,
  required IconData icon,
  required String label,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    decoration: BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.border, width: 1.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: theme.primary, size: 22),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '••••';
  return '••••${digits.substring(digits.length - 2)}';
}

String _locationLine(String? area, String? county) {
  final parts = [area, county].where((p) => p != null && p.isNotEmpty);
  return parts.isEmpty ? '—' : parts.join(', ');
}
