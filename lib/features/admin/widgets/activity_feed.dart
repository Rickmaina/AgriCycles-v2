import 'package:flutter/material.dart';

import '../../../core/theme/role_theme.dart';
import '../../../core/utils/extensions.dart';
import '../controllers/admin_controller.dart';

/// Recent activity across orders, disputes, verifications, payments.
/// Sorted newest-first by the provider; capped at 8 entries.
class ActivityFeed extends StatelessWidget {
  final List<ActivityEvent> events;
  final RoleTheme theme;

  const ActivityFeed({
    super.key,
    required this.events,
    this.theme = RoleTheme.admin,
  });

  Color _toneColor(ActivityTone tone) {
    switch (tone) {
      case ActivityTone.info:
        return theme.primary;
      case ActivityTone.success:
        return const Color(0xFF2E7D32);
      case ActivityTone.warning:
        return theme.accent;
      case ActivityTone.danger:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(fontSize: 12, color: theme.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          _Row(event: events[i], color: _toneColor(events[i].tone), theme: theme),
          if (i < events.length - 1)
            Divider(height: 1, color: theme.border),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final ActivityEvent event;
  final Color color;
  final RoleTheme theme;

  const _Row({required this.event, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.text,
              style: TextStyle(
                fontSize: 12,
                color: theme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.at.relative,
            style: TextStyle(fontSize: 10, color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}
