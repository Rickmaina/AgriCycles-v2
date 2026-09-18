import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/marketplace_service.dart';
import 'controllers/shell_tab_controller.dart';
import '../../shared/widgets/hero_action_card.dart';
import '../../shared/widgets/section_header.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    const theme = RoleTheme.farmer;
    final listings = ref.watch(marketplaceProvider).listings;
    final myListings = listings.where((l) => l.sellerId == user.id).toList();

    return Container(
      color: theme.background,
      child: ListView(
        padding: EdgeInsets.all(theme.cardPadding),
        children: [
          HeroActionCard(
            theme: theme,
            icon: Icons.agriculture_outlined,
            headline: _heroHeadline(myListings.length),
            subline: _heroSubline(myListings.length),
            actionLabel: 'Open market',
            onAction: () => ref.read(shellTabProvider.notifier).goTo(1),
          ),
          SizedBox(height: theme.sectionSpacing),
          _StatGrid(theme: theme, myListings: myListings.length),
          SizedBox(height: theme.sectionSpacing),
          const SectionHeader(
            theme: theme,
            icon: Icons.storefront_outlined,
            title: 'Trade',
          ),
          const _ActionCard(
            theme: theme,
            actions: [
              _ActionData(
                icon: Icons.add_box_outlined,
                title: 'Sell a resource',
                subtitle: 'List crop waste, manure, feed',
              ),
              _ActionData(
                icon: Icons.search,
                title: 'Browse listings',
                subtitle: 'See what buyers want nearby',
              ),
              _ActionData(
                icon: Icons.campaign_outlined,
                title: 'Post a need',
                subtitle: 'Buy-first: state what you need',
              ),
            ],
          ),
          SizedBox(height: theme.sectionSpacing),
          const SectionHeader(
            theme: theme,
            icon: Icons.groups_outlined,
            title: 'Community',
          ),
          const _ActionCard(
            theme: theme,
            actions: [
              _ActionData(
                icon: Icons.groups_outlined,
                title: 'Join a community order',
                subtitle: 'Pool resources with other farmers',
              ),
              _ActionData(
                icon: Icons.map_outlined,
                title: 'Route & pickup',
                subtitle: 'Admin-managed logistics',
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _heroHeadline(int myListings) {
    if (myListings == 0) return 'Start selling today';
    return 'Keep the momentum going';
  }

  String _heroSubline(int myListings) {
    if (myListings == 0) {
      return 'Post your first listing and reach buyers across the county.';
    }
    return 'You have $myListings active listing${myListings == 1 ? "" : "s"}. Check new offers on the market.';
  }
}

class _StatGrid extends StatelessWidget {
  final RoleTheme theme;
  final int myListings;

  const _StatGrid({required this.theme, required this.myListings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                theme: theme,
                icon: Icons.storefront_outlined,
                label: 'My listings',
                value: '$myListings',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                theme: theme,
                icon: Icons.receipt_long_outlined,
                label: 'Open orders',
                value: '1',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Stat(
                theme: theme,
                icon: Icons.campaign_outlined,
                label: 'Buy requests',
                value: '5',
                valueTone: theme.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                theme: theme,
                icon: Icons.people_alt_outlined,
                label: 'Community',
                value: '2',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final RoleTheme theme;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueTone;

  const _Stat({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.valueTone,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.textMuted),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueTone ?? theme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final RoleTheme theme;
  final List<_ActionData> actions;

  const _ActionCard({required this.theme, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            _ActionRow(theme: theme, data: actions[i]),
            if (i < actions.length - 1) Divider(height: 1, color: theme.border),
          ],
        ],
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ActionRow extends StatelessWidget {
  final RoleTheme theme;
  final _ActionData data;

  const _ActionRow({required this.theme, required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.primaryMuted,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, color: theme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.textMuted),
          ],
        ),
      ),
    );
  }
}
