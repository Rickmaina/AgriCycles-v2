import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';

class NotificationController {
  NotificationController(this._ref);
  final Ref _ref;

  NotificationService get _svc => _ref.read(notificationProvider.notifier);

  void notifyOrder({
    required String recipientId,
    required String orderId,
    required String resourceType,
    required OrderState state,
  }) {
    _svc.push(
      NotificationModel(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        recipientId: recipientId,
        type: NotificationType.order,
        title: 'Order ${state.label.toLowerCase()}',
        body: '$resourceType — order #${orderId.substring(3)}',
        target: NotificationTarget.order,
        targetId: orderId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyDispute({
    required String recipientId,
    required String disputeId,
    required String orderResourceType,
    required String message,
  }) {
    _svc.push(
      NotificationModel(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        recipientId: recipientId,
        type: NotificationType.dispute,
        title: 'Dispute update',
        body: '$orderResourceType — $message',
        target: NotificationTarget.dispute,
        targetId: disputeId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyCommunity({
    required String recipientId,
    required String preOrderId,
    required String resourceType,
    required String message,
  }) {
    _svc.push(
      NotificationModel(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        recipientId: recipientId,
        type: NotificationType.community,
        title: 'Community order update',
        body: '$resourceType — $message',
        target: NotificationTarget.preOrder,
        targetId: preOrderId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void markRead(String id) => _svc.markRead(id);

  void markAllRead(String userId) => _svc.markAllRead(userId);

  void clear(String userId) => _svc.clear(userId);
}

final notificationControllerProvider =
    Provider<NotificationController>((ref) => NotificationController(ref));
