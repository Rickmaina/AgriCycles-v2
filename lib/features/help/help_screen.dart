import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _HelpItem(
        icon: Icons.storefront_outlined,
        title: 'How the marketplace works',
        subtitle:
            'Browse by category and county, then send a clear offer with quantity and delivery details.',
      ),
      const _HelpItem(
        icon: Icons.verified_user_outlined,
        title: 'Quality before publish',
        subtitle:
            'If your item is not recognized, choose “Other — describe what you’re selling” and it goes to pending review.',
      ),
      const _HelpItem(
        icon: Icons.shield_outlined,
        title: 'Privacy-first location',
        subtitle:
            'Only the broad area is public. Exact coordinates remain private until an order is accepted.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help & quick tips')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _HelpTile(item: items[i]),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final _HelpItem item;

  const _HelpTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _HelpItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
