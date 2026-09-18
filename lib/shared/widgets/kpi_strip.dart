import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// A data-dense row of metrics. Used by company (procurement KPIs) and
/// admin (queue depths). Reads colors from the current [RoleTheme] so
/// the same strip feels like part of the surrounding role.
class KpiStrip extends StatelessWidget {
  final List<KpiItem> items;
  final RoleTheme theme;

  const KpiStrip({
    super.key,
    required this.items,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _KpiCell(item: items[i], theme: theme)),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 40,
                color: theme.border,
              ),
          ],
        ],
      ),
    );
  }
}

class KpiItem {
  final String label;
  final String value;
  final IconData? icon;
  final KpiTone tone;

  const KpiItem({
    required this.label,
    required this.value,
    this.icon,
    this.tone = KpiTone.normal,
  });
}

enum KpiTone { normal, emphasis, info, warning, attention, danger }

class _KpiCell extends StatelessWidget {
  final KpiItem item;
  final RoleTheme theme;

  const _KpiCell({required this.item, required this.theme});

  Color get _valueColor {
    switch (item.tone) {
      case KpiTone.normal:
        return theme.textPrimary;
      case KpiTone.emphasis:
        return theme.primary;
      case KpiTone.info:
        return theme.primary;
      case KpiTone.warning:
        return theme.accent;
      case KpiTone.attention:
        return theme.accent;
      case KpiTone.danger:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: theme.textMuted),
            const SizedBox(height: 6),
          ],
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: theme.denseLists ? 20 : 22,
              fontWeight: FontWeight.w700,
              color: _valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
