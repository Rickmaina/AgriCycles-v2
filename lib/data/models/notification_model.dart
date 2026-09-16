import '../../core/constants/enums.dart';

/// In-app notification. Optionally carries a deep-link reference so
/// tapping a notification can route the user to the relevant screen.
class NotificationModel {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;

  /// Optional reference used for deep-linking.
  /// e.g. target = order, targetId = 'ord123'
  final NotificationTarget? target;
  final String? targetId;

  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.target,
    this.targetId,
    this.read = false,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        target: target,
        targetId: targetId,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

enum NotificationType {
  order,
  offer,
  counterOffer,
  community,
  dispute,
  verification,
  system,
}

extension NotificationTypeLabel on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.order:        return 'Order';
      case NotificationType.offer:        return 'Offer';
      case NotificationType.counterOffer: return 'Counter-offer';
      case NotificationType.community:    return 'Community';
      case NotificationType.dispute:      return 'Dispute';
      case NotificationType.verification: return 'Verification';
      case NotificationType.system:       return 'System';
    }
  }
}

enum NotificationTarget { order, listing, offer, preOrder, dispute, verification }
