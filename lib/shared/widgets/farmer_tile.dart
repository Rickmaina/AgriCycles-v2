import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// Large tappable tile for farmer-facing navigation.
///
/// The whole row is one tap target. Farmers choose between 2–4 of
/// these on the home screen, and between 2–3 in nested screens.
class FarmerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;
  final Color? iconBackground;
  final bool enabled;

  const FarmerTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
    this.iconBackground,
    this.enabled = true,
  });

  static const double _minHeight = 96;
  static const double _radius = 16;
  static const double _iconBox = 56;
  static const double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final active = enabled && onTap != null;
    final iconBg = iconBackground ?? theme.primaryMuted;
    final iconFg = iconBackground != null ? Colors.white : theme.primary;
    final contentColor =
        active ? theme.textPrimary : theme.textMuted;

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: active ? theme.border : theme.border.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: _iconBox,
                height: _iconBox,
                decoration: BoxDecoration(
                  color: active
                      ? iconBg
                      : iconBg.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: _iconSize,
                  color: active
                      ? iconFg
                      : iconFg.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: contentColor,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: active
                              ? theme.textSecondary
                              : theme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 24,
                color: active ? theme.textMuted : theme.textMuted.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
