import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/base_card.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileSummary(
          name: user.name,
          subtitle:
              '${user.farmerType?.label ?? "Farmer"} • ${user.area ?? ""}, ${user.county ?? ""}',
        ),
        const SizedBox(height: 16),
        const _QuickStats(),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Trade'),
        const SizedBox(height: 10),
        const _TradeActions(),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Community'),
        const SizedBox(height: 10),
        const _CommunityActions(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String name;
  final String subtitle;

  const _ProfileSummary({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.storefront,
                label: 'My listings',
                value: '3',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long,
                label: 'Open orders',
                value: '1',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.campaign_outlined,
                label: 'Buy requests',
                value: '5 nearby',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.people_alt_outlined,
                label: 'Community',
                value: '2 active',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeActions extends StatelessWidget {
  const _TradeActions();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: const [
          _ActionRow(
            icon: Icons.add_box_outlined,
            title: 'Sell a resource',
            subtitle: 'List crop waste, manure, feed',
          ),
          Divider(height: 20, color: AppColors.border),
          _ActionRow(
            icon: Icons.search,
            title: 'Browse listings',
            subtitle: 'See what buyers want nearby',
          ),
          Divider(height: 20, color: AppColors.border),
          _ActionRow(
            icon: Icons.campaign_outlined,
            title: 'Post a need',
            subtitle: 'Buy-first: state what you need',
          ),
        ],
      ),
    );
  }
}

class _CommunityActions extends StatelessWidget {
  const _CommunityActions();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: const [
          _ActionRow(
            icon: Icons.groups_outlined,
            title: 'Join a community order',
            subtitle: 'Pool resources with other farmers',
          ),
          Divider(height: 20, color: AppColors.border),
          _ActionRow(
            icon: Icons.map_outlined,
            title: 'Route & pickup',
            subtitle: 'Admin-managed logistics',
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
