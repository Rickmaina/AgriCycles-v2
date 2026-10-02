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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String? ?? json['user_id'] as String,
      type: _parseType(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      target: _parseTarget(
        json['target']?['type'] as String? ?? json['target'] as String?,
      ),
      targetId:
          json['target']?['id'] as String? ?? json['target_id'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_id': recipientId,
        'type': type.name,
        'title': title,
        'body': body,
        if (target != null)
          'target': {
            'type': target!.name,
            'id': targetId,
          },
        'read': read,
        'created_at': createdAt.toIso8601String(),
      };

  static NotificationType _parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'order':
        return NotificationType.order;
      case 'offer':
        return NotificationType.offer;
      case 'counteroffer':
      case 'counter_offer':
        return NotificationType.counterOffer;
      case 'community':
        return NotificationType.community;
      case 'dispute':
        return NotificationType.dispute;
      case 'verification':
        return NotificationType.verification;
      default:
        return NotificationType.system;
    }
  }

  static NotificationTarget? _parseTarget(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'order':
        return NotificationTarget.order;
      case 'listing':
        return NotificationTarget.listing;
      case 'offer':
        return NotificationTarget.offer;
      case 'preorder':
      case 'pre_order':
      case 'community':
        return NotificationTarget.preOrder;
      case 'dispute':
        return NotificationTarget.dispute;
      case 'verification':
        return NotificationTarget.verification;
      default:
        return null;
    }
  }
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
      case NotificationType.order:
        return 'Order';
      case NotificationType.offer:
        return 'Offer';
      case NotificationType.counterOffer:
        return 'Counter-offer';
      case NotificationType.community:
        return 'Community';
      case NotificationType.dispute:
        return 'Dispute';
      case NotificationType.verification:
        return 'Verification';
      case NotificationType.system:
        return 'System';
    }
  }
}

enum NotificationTarget {
  order,
  listing,
  offer,
  preOrder,
  dispute,
  verification,
}
