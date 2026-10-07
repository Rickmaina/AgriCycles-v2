import 'package:flutter/material.dart';

import '../../../core/theme/role_theme.dart';

/// One card primitive for every admin queue screen.
///
/// Shape: icon + title + status chip on top, optional meta line,
/// optional multi-line description, stack of label:value rows,
/// optional trailing text, optional actions row.
/// Reads colours from [RoleTheme.admin] by default.
class AdminQueueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? statusChip;
  final String? meta;
  final String? description;
  final List<AdminQueueLine> lines;
  final String? trailingText;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final RoleTheme theme;

  const AdminQueueCard({
    super.key,
    required this.icon,
    required this.title,
    this.statusChip,
    this.meta,
    this.description,
    this.lines = const [],
    this.trailingText,
    this.actions = const [],
    this.onTap,
    this.theme = RoleTheme.admin,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              if (statusChip != null) statusChip!,
            ],
          ),
          if (meta != null) ...[
            const SizedBox(height: 6),
            Text(
              meta!,
              style: TextStyle(fontSize: 12, color: theme.textSecondary),
            ),
          ],
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          for (final line in lines) ...[
            const SizedBox(height: 4),
            _Line(label: line.label, value: line.value, theme: theme),
          ],
          if (trailingText != null) ...[
            const SizedBox(height: 8),
            Text(
              trailingText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(theme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.cardRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class AdminQueueLine {
  final String label;
  final String value;
  const AdminQueueLine(this.label, this.value);
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final RoleTheme theme;
  const _Line({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
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
}

/// Shared status chip for admin queues.
class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const AdminStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
