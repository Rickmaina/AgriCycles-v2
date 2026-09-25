import 'package:flutter_test/flutter_test.dart';
import 'package:agricycles/data/services/marketplace_service.dart';
import 'package:agricycles/data/services/order_service.dart';
import 'package:agricycles/data/models/geo_location.dart';
import 'package:agricycles/data/models/listing_model.dart';

void main() {
  test('Marketplace.createOffer sets deviceCaptured for coords', () {
    final marketplace = MarketplaceService();

    final listing = ListingModel(
      id: 'l-test-1',
      sellerId: 's1',
      sellerName: 'Seller One',
      resourceType: 'sugar',
      category: 'grain',
      quantity: 100,
      unit: 'kg',
      pricePerUnit: 10.0,
      location: GeoLocation(
        county: 'Nairobi',
        subCounty: 'Central',
        area: 'Area 1',
        lat: -1.2921,
        lng: 36.8219,
        source: LocationSource.deviceCaptured,
      ),
    );

    marketplace.addListing(listing);

    final offer = marketplace.createOffer(
      listing: listing,
      buyerId: 'b1',
      buyerName: 'Buyer One',
      quantity: 10,
      pricePerUnit: 9.0,
      deliveryLocation: GeoLocation(
        county: 'Nairobi',
        subCounty: 'Central',
        area: 'Dest',
        lat: -1.3000,
        lng: 36.8200,
        source:
            LocationSource.selfReported, // caller-provided should be overridden
      ),
    );

    // The service must normalize the source to deviceCaptured because coords exist
    final stored = marketplace.offerById(offer.id);
    expect(stored, isNotNull);
    expect(stored!.deliveryLocation.hasCoordinates, isTrue);
    expect(stored.deliveryLocation.source, LocationSource.deviceCaptured);
  });

  test(
      'Coordinates are masked for non-party before acceptance and revealed after',
      () {
    final marketplace = MarketplaceService();
    final orders = OrderService();

    const sellerId = 'sellerX';
    const buyerId = 'buyerY';
    const outsider = 'outsiderZ';

    final listing = ListingModel(
      id: 'l-test-2',
      sellerId: sellerId,
      sellerName: 'Seller X',
      resourceType: 'maize',
      category: 'grain',
      quantity: 200,
      unit: 'kg',
      pricePerUnit: 5.0,
      location: GeoLocation(
        county: 'Kakamega',
        subCounty: 'Central',
        area: 'Farm',
        lat: 0.2833,
        lng: 34.7500,
        source: LocationSource.deviceCaptured,
      ),
    );

    marketplace.addListing(listing);

    final offer = marketplace.createOffer(
      listing: listing,
      buyerId: buyerId,
      buyerName: 'Buyer Y',
      quantity: 50,
      pricePerUnit: 4.5,
      deliveryLocation: GeoLocation(
        county: 'Kakamega',
        subCounty: 'Central',
        area: 'Depot',
        lat: 0.2800,
        lng: 34.7600,
        source: LocationSource.selfReported,
      ),
    );

    // Non-party views: offer should be masked
    final publicOffer = marketplace.publicOfferForViewer(offer, outsider);
    expect(publicOffer.deliveryLocation.lat, isNull);
    expect(publicOffer.deliveryLocation.lng, isNull);

    // Accept offer -> create order
    final order = orders.createFromOffer(
      listingId: offer.listingId,
      resourceType: listing.resourceType,
      unit: listing.unit,
      buyerId: offer.buyerId,
      buyerName: offer.buyerName,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      quantity: offer.quantity,
      pricePerUnit: offer.pricePerUnit,
      pickupLocation: listing.location,
      pickupCounty: listing.county,
      pickupSubCounty: listing.subCounty,
      pickupArea: listing.area,
      deliveryLocation: offer.deliveryLocation,
      deliveryCounty: offer.deliveryCounty,
      deliverySubCounty: offer.deliverySubCounty,
      deliveryArea: offer.deliveryArea,
      deliveryNotes: offer.deliveryNotes,
    );

    // Outsider should not see precise coords on the order view
    final publicOrderOutsider = orders.publicOrderForViewer(order, outsider);
    expect(publicOrderOutsider.pickupLocation.lat, isNull);
    expect(publicOrderOutsider.deliveryLocation.lat, isNull);

    // Buyer and seller should see precise coords
    final publicOrderBuyer = orders.publicOrderForViewer(order, buyerId);
    expect(publicOrderBuyer.pickupLocation.lat, isNotNull);
    expect(publicOrderBuyer.deliveryLocation.lat, isNotNull);

    final publicOrderSeller = orders.publicOrderForViewer(order, sellerId);
    expect(publicOrderSeller.pickupLocation.lat, isNotNull);
    expect(publicOrderSeller.deliveryLocation.lat, isNotNull);
  });
}
