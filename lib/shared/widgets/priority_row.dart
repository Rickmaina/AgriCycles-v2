import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// A dense action row for admin and company queues. Reads urgency from
/// [tone] to colour the left rail and icon background.
///
/// Visually tighter than BaseCard — 1-line title, 1-line subtitle,
/// trailing metric + chevron. Designed to stack 6–10 on a screen
/// without feeling crowded.
class PriorityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final PriorityTone tone;
  final VoidCallback? onTap;
  final RoleTheme theme;

  const PriorityRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingValue,
    this.tone = PriorityTone.neutral,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final (railColor, iconBg) = _toneColors();

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(theme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.cardRadius),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(theme.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: theme.rowMinHeight,
                decoration: BoxDecoration(
                  color: railColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(theme.cardRadius),
                    bottomLeft: Radius.circular(theme.cardRadius),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: railColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailingValue != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: railColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trailingValue!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: railColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 20, color: theme.textMuted),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _toneColors() {
    switch (tone) {
      case PriorityTone.neutral:
        return (theme.textMuted, theme.textMuted.withValues(alpha: 0.10));
      case PriorityTone.info:
        return (theme.primary, theme.primaryMuted);
      case PriorityTone.attention:
        return (theme.accent, theme.accent.withValues(alpha: 0.12));
      case PriorityTone.urgent:
        return (
          const Color(0xFFC62828),
          const Color(0xFFC62828).withValues(alpha: 0.10),
        );
    }
  }
}

enum PriorityTone { neutral, info, attention, urgent }
