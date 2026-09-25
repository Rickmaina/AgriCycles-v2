import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_tile.dart';

/// Farmer profile. One screen, five rows max.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(theme, user.name, user.county, user.area),
            const SizedBox(height: 20),
            _row(
              theme: theme,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _maskPhone(user.phone),
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

  Widget _header(
    RoleTheme theme,
    String name,
    String? county,
    String? area,
  ) {
    final locationParts = [area, county]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    final locationLine =
        locationParts.isEmpty ? 'Farmer' : locationParts.join(', ');

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationLine,
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

  Widget _row({
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
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
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
}
