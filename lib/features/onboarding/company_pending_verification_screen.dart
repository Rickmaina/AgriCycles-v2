import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/company_profile_service.dart';
import '../../shared/widgets/farmer_action_button.dart';

/// What a company sees after submitting for verification, until
/// Admin approves them.
///
/// In debug mode, a "simulate approval" button flips the local
/// verification status so the full flow can be walked through
/// without a real admin.
class CompanyPendingVerificationScreen extends ConsumerWidget {
  const CompanyPendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final profile = ref.watch(companyProfileProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: theme.accent,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Submission received',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Our team will review your business details. '
                      'This usually takes 1–2 working days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (profile != null) ...[
                      _recapCard(theme, profile),
                      const SizedBox(height: 24),
                    ],

                    _nextSteps(theme),

                    if (kDebugMode) ...[
                      const SizedBox(height: 32),
                      _devBlock(context, ref, theme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapCard(RoleTheme theme, dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your submission',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _line(theme, 'Business', profile.businessName as String),
          const SizedBox(height: 4),
          _line(theme, 'Type', profile.businessType as String),
          const SizedBox(height: 4),
          _line(theme, 'Contact', profile.contactName as String),
          const SizedBox(height: 4),
          _line(
            theme,
            'Base',
            '${profile.base.county}, ${profile.base.subCounty}',
          ),
        ],
      ),
    );
  }

  Widget _line(RoleTheme theme, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _nextSteps(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _bullet(theme, 'We check your business details.'),
          _bullet(theme, 'You may be asked for documents by SMS or email.'),
          _bullet(theme, 'Once approved, you can post needs and make offers.'),
        ],
      ),
    );
  }

  Widget _bullet(RoleTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devBlock(BuildContext context, WidgetRef ref, RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.danger.withValues(alpha: 0.30),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 18, color: theme.danger),
              const SizedBox(width: 8),
              Text(
                'Developer shortcuts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FarmerActionButton(
            label: 'Simulate approval',
            icon: Icons.verified,
            variant: FarmerButtonVariant.secondary,
            onPressed: () {
              ref.read(authProvider.notifier).mockApproveVerification();
              context.go(AppRoutes.companyHome);
            },
          ),
          const SizedBox(height: 8),
          FarmerActionButton(
            label: 'Simulate rejection',
            icon: Icons.cancel_outlined,
            variant: FarmerButtonVariant.secondary,
            onPressed: () {
              ref.read(authProvider.notifier).mockRejectVerification();
            },
          ),
        ],
      ),
    );
  }
}
