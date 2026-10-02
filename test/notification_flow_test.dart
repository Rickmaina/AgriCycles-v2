import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:agricycles/core/constants/enums.dart';
import 'package:agricycles/data/models/geo_location.dart';
import 'package:agricycles/data/models/listing_model.dart';
import 'package:agricycles/data/models/notification_model.dart';
import 'package:agricycles/data/services/notification_service.dart';
import 'package:agricycles/features/marketplace/controllers/marketplace_controller.dart';
import 'package:agricycles/features/orders/controllers/orders_controller.dart';

void main() {
  test('making an offer creates a notification for the seller', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final listing = ListingModel(
      id: 'l1',
      sellerId: 's1',
      sellerName: 'Seller One',
      resourceType: 'Maize',
      category: 'Grains',
      quantity: 40,
      unit: 'bags',
      pricePerUnit: 1200,
      location: GeoLocation(
        county: 'Nakuru',
        subCounty: 'Naivasha',
        area: 'Maiella',
      ),
      status: ListingStatus.active,
    );

    final offer = container.read(marketplaceControllerProvider).makeOffer(
          listing: listing,
          buyerId: 'b1',
          buyerName: 'Buyer One',
          quantity: 10,
          pricePerUnit: 1250,
        );

    final notifications = container.read(notificationProvider);
    expect(
      notifications.any(
        (n) =>
            n.recipientId == 's1' &&
            n.target == NotificationTarget.offer &&
            n.targetId == offer.id,
      ),
      isTrue,
    );
  });

  test('creating an order from an accepted offer notifies both parties', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final order = container.read(ordersControllerProvider).createFromOffer(
          listingId: 'l2',
          resourceType: 'Maize',
          unit: 'bags',
          buyerId: 'b2',
          buyerName: 'Buyer Two',
          sellerId: 's2',
          sellerName: 'Seller Two',
          quantity: 8,
          pricePerUnit: 1300,
        );

    final notifications = container.read(notificationProvider);
    expect(
      notifications.any(
        (n) =>
            n.recipientId == 'b2' &&
            n.target == NotificationTarget.order &&
            n.targetId == order.id,
      ),
      isTrue,
    );
    expect(
      notifications.any(
        (n) =>
            n.recipientId == 's2' &&
            n.target == NotificationTarget.order &&
            n.targetId == order.id,
      ),
      isTrue,
    );
  });
}
