import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';

class NotificationController {
  NotificationController(this._ref);
  final Ref _ref;

  NotificationService get _svc => _ref.read(notificationProvider.notifier);

  // ── Order lifecycle ─────────────────────────────────────────────────────

  void notifyOrder({
    required String recipientId,
    required String orderId,
    required String resourceType,
    required OrderState state,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.order,
        title: 'Order ${state.label.toLowerCase()}',
        body: '$resourceType — order #${_short(orderId)}',
        target: NotificationTarget.order,
        targetId: orderId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyPaymentVerified({
    required String recipientId,
    required String orderId,
    required String resourceType,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.order,
        title: 'Payment verified',
        body:
            '$resourceType — order #${_short(orderId)}. Pickup can now be arranged.',
        target: NotificationTarget.order,
        targetId: orderId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyPickupScheduled({
    required String recipientId,
    required String orderId,
    required String resourceType,
    required String when,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.order,
        title: 'Pickup scheduled',
        body: '$resourceType — order #${_short(orderId)} · $when',
        target: NotificationTarget.order,
        targetId: orderId,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ── Offers ──────────────────────────────────────────────────────────────

  void notifyOfferReceived({
    required String recipientId,
    required String offerId,
    required String resourceType,
    required String amountLabel,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.offer,
        title: 'New offer received',
        body: '$resourceType — $amountLabel',
        target: NotificationTarget.offer,
        targetId: offerId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyCounterOffer({
    required String recipientId,
    required String offerId,
    required String resourceType,
    required String amountLabel,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.counterOffer,
        title: 'Counter-offer received',
        body: '$resourceType — $amountLabel',
        target: NotificationTarget.offer,
        targetId: offerId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyOfferAccepted({
    required String recipientId,
    required String offerId,
    required String resourceType,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.offer,
        title: 'Offer accepted',
        body: '$resourceType — your offer was accepted',
        target: NotificationTarget.offer,
        targetId: offerId,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ── Disputes ────────────────────────────────────────────────────────────

  void notifyDispute({
    required String recipientId,
    required String disputeId,
    required String orderResourceType,
    required String message,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
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

  // ── Community ───────────────────────────────────────────────────────────

  void notifyCommunity({
    required String recipientId,
    required String preOrderId,
    required String resourceType,
    required String message,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
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

  // ── Listings / verification ─────────────────────────────────────────────

  void notifyListingStatus({
    required String recipientId,
    required String listingId,
    required String resourceType,
    required String statusLabel,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.system,
        title: 'Listing $statusLabel',
        body: '$resourceType is now $statusLabel',
        target: NotificationTarget.listing,
        targetId: listingId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyVerification({
    required String recipientId,
    required String message,
  }) {
    _svc.push(
      NotificationModel(
        id: _id(),
        recipientId: recipientId,
        type: NotificationType.verification,
        title: 'Verification update',
        body: message,
        target: NotificationTarget.verification,
        targetId: recipientId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> registerPushToken({
    required String userId,
    required String token,
  }) async {
    if (userId.isEmpty || token.isEmpty) return;
  }

  void markRead(String id) => _svc.markRead(id);

  void markAllRead(String userId) => _svc.markAllRead(userId);

  void clear(String userId) => _svc.clear(userId);

  String _id() => 'n${DateTime.now().microsecondsSinceEpoch}';

  String _short(String id) {
    if (id.length <= 6) return id;
    return id.substring(id.length - 6);
  }
}

final notificationControllerProvider =
    Provider<NotificationController>((ref) => NotificationController(ref));
