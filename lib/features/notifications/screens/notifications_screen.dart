import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../community/screens/community_order_detail_screen.dart';
import '../../disputes/screens/dispute_detail_screen.dart';
import '../../orders/order_detail_screen.dart';
import '../controllers/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final list = ref.watch(myNotificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (list.any((n) => !n.read))
            TextButton(
              onPressed: () =>
                  ref.read(notificationControllerProvider).markAllRead(user.id),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              subtitle:
                  'Order updates, disputes, and community activity show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NotificationCard(
                notification: list[i],
                onTap: () {
                  ref.read(notificationControllerProvider).markRead(list[i].id);
                  _handleNavigation(context, list[i]);
                },
              ),
            ),
    );
  }

  void _handleNavigation(BuildContext context, NotificationModel notification) {
    switch (notification.target) {
      case NotificationTarget.order:
        if (notification.targetId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailScreen(orderId: notification.targetId!),
            ),
          );
        }
        break;
      case NotificationTarget.dispute:
        if (notification.targetId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DisputeDetailScreen(disputeId: notification.targetId!),
            ),
          );
        }
        break;
      case NotificationTarget.preOrder:
        if (notification.targetId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommunityOrderDetailScreen(
                  preOrderId: notification.targetId!),
            ),
          );
        }
        break;
      case NotificationTarget.listing:
      case NotificationTarget.offer:
      case NotificationTarget.verification:
      default:
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    final (icon, color) = _style(notification.type);

    return Material(
      color: unread
          ? AppColors.primary.withValues(alpha: 0.04)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.createdAt.relative,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _style(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return (Icons.receipt_long_outlined, AppColors.primary);
      case NotificationType.offer:
        return (Icons.local_offer_outlined, AppColors.info);
      case NotificationType.counterOffer:
        return (Icons.swap_horiz, AppColors.info);
      case NotificationType.community:
        return (Icons.groups_outlined, AppColors.secondary);
      case NotificationType.dispute:
        return (Icons.gavel_outlined, AppColors.danger);
      case NotificationType.verification:
        return (Icons.verified_user_outlined, AppColors.success);
      case NotificationType.system:
        return (Icons.info_outline, AppColors.textMuted);
    }
  }
}
