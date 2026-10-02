import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/marketplace_service.dart';
import '../../features/community/screens/community_order_detail_screen.dart';
import '../../features/disputes/screens/dispute_detail_screen.dart';
import '../../features/marketplace/screens/farmer_listing_detail_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../constants/app_routes.dart';

/// Central deep-link resolver for AgriCycles notifications.
class NotificationDeepLink {
  NotificationDeepLink._();

  static bool navigate(BuildContext context, NotificationModel notification) {
    final target = notification.target;
    final id = notification.targetId;

    if (target == null || id == null || id.isEmpty) {
      return false;
    }

    switch (target) {
      case NotificationTarget.order:
        _push(context, OrderDetailScreen(orderId: id));
        return true;
      case NotificationTarget.dispute:
        _push(context, DisputeDetailScreen(disputeId: id));
        return true;
      case NotificationTarget.preOrder:
        _push(context, CommunityOrderDetailScreen(preOrderId: id));
        return true;
      case NotificationTarget.listing:
        _openListing(context, id);
        return true;
      case NotificationTarget.offer:
        context.push(AppRoutes.incomingOffers);
        return true;
      case NotificationTarget.verification:
        context.push(AppRoutes.profile);
        return true;
    }
  }

  static bool navigateFromRaw(
    BuildContext context, {
    required String? targetType,
    required String? targetId,
  }) {
    if (targetType == null || targetId == null || targetId.isEmpty) {
      return false;
    }

    final target = _parseTarget(targetType);
    if (target == null) return false;

    final fake = NotificationModel(
      id: 'tmp',
      recipientId: '',
      type: NotificationType.system,
      title: '',
      body: '',
      target: target,
      targetId: targetId,
      createdAt: DateTime.now(),
    );
    return navigate(context, fake);
  }

  static NotificationTarget? _parseTarget(String raw) {
    switch (raw.toLowerCase().trim()) {
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

  static void _openListing(BuildContext context, String id) {
    final container = ProviderScope.containerOf(context, listen: false);
    final listing =
        container.read(marketplaceProvider.notifier).listingById(id);
    if (listing != null) {
      _push(context, FarmerListingDetailScreen(listing: listing));
      return;
    }

    context.push(AppRoutes.browse);
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
