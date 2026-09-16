import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';

class NotificationService extends StateNotifier<List<NotificationModel>> {
  NotificationService() : super(_seed());

  static List<NotificationModel> _seed() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'n1',
        recipientId: 'u1',
        type: NotificationType.order,
        title: 'Payment secured',
        body: 'Sugarcane bagasse — order #d2 is now awaiting pickup',
        target: NotificationTarget.order,
        targetId: 'ord2',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      NotificationModel(
        id: 'n2',
        recipientId: 'u1',
        type: NotificationType.dispute,
        title: 'Dispute raised',
        body: 'Chicken litter — order #d4 is now under review',
        target: NotificationTarget.dispute,
        targetId: 'ord4',
        read: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationModel(
        id: 'n3',
        recipientId: 'u3',
        type: NotificationType.community,
        title: 'Community order target reached',
        body: 'Maize stalks — contributions have locked',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
    ];
  }

  List<NotificationModel> forUser(String userId) {
    final list =
        state.where((n) => n.recipientId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int unreadCount(String userId) => state
      .where((n) => n.recipientId == userId && !n.read)
      .length;

  void push(NotificationModel notification) {
    state = [notification, ...state];
  }

  void markRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
  }

  void markAllRead(String userId) {
    state = state
        .map((n) => n.recipientId == userId ? n.copyWith(read: true) : n)
        .toList();
  }

  void clear(String userId) {
    state = state.where((n) => n.recipientId != userId).toList();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationService, List<NotificationModel>>(
  (ref) => NotificationService(),
);

final myNotificationsProvider =
    Provider.family<List<NotificationModel>, String>((ref, userId) {
  final list = ref
      .watch(notificationProvider)
      .where((n) => n.recipientId == userId)
      .toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

final myUnreadCountProvider =
    Provider.family<int, String>((ref, userId) {
  return ref
      .watch(notificationProvider)
      .where((n) => n.recipientId == userId && !n.read)
      .length;
});
