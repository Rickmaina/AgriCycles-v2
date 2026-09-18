import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// Consistent section header. Icon + title on the left, optional
/// trailing action ("See all", count badge, etc.) on the right.
class SectionHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final String? badge;
  final RoleTheme theme;

  const SectionHeader({
    super.key,
    this.icon,
    required this.title,
    this.trailingText,
    this.onTrailingTap,
    this.badge,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.textSecondary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: theme.sectionTitleStyle,
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailingText != null && onTrailingTap != null)
            TextButton(
              onPressed: onTrailingTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: theme.primary,
              ),
              child: Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
