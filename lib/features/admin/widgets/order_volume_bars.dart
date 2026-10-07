import 'package:flutter/material.dart';

import '../../../core/theme/role_theme.dart';
import '../controllers/admin_controller.dart';

/// 7-day order volume chart. Last bar = today, highlighted.
class OrderVolumeBars extends StatelessWidget {
  final List<OrderVolumePoint> points;
  final RoleTheme theme;

  const OrderVolumeBars({
    super.key,
    required this.points,
    this.theme = RoleTheme.admin,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 60);
    }

    final maxCount = points
        .map((p) => p.count)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < points.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Bar(
                    count: points[i].count,
                    max: maxCount,
                    isToday: i == points.length - 1,
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < points.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _dayLabels[points[i].day.weekday - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == points.length - 1
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: i == points.length - 1
                        ? theme.textPrimary
                        : theme.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final int count;
  final int max;
  final bool isToday;
  final RoleTheme theme;

  const _Bar({
    required this.count,
    required this.max,
    required this.isToday,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Reserve 6px min so empty days still show a stub.
    final ratio = max == 0 ? 0.0 : count / max;
    final height = 6.0 + ratio * 54.0;
    final color = isToday ? theme.primary : theme.primaryMuted;

    return Tooltip(
      message: '$count order${count == 1 ? "" : "s"}',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}
