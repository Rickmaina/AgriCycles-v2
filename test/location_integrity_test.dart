import 'package:agricycles/core/constants/enums.dart';
import 'package:agricycles/data/models/geo_location.dart';
import 'package:agricycles/data/models/listing_model.dart';
import 'package:agricycles/data/models/user_model.dart';
import 'package:agricycles/data/services/auth_service.dart';
import 'package:agricycles/data/services/marketplace_service.dart';
import 'package:agricycles/domain/location_catalog.dart';
import 'package:agricycles/features/community/screens/create_pre_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await LocationCatalog.load();
  });

  test('GeoLocation rejects Siaya as a sub-county of Nakuru', () {
    expect(
      () => GeoLocation(
        county: 'Nakuru',
        subCounty: 'Siaya',
        area: 'Example',
      ),
      throwsArgumentError,
    );
  });

  test('pending-review listings do not appear in marketplace browse results',
      () {
    final service = MarketplaceService();
    final listing = ListingModel(
      id: 'pending-1',
      sellerId: 'u1',
      sellerName: 'Test Seller',
      resourceType: 'Maize stalks',
      category: 'Crop residue',
      quantity: 2,
      unit: 'tonnes',
      pricePerUnit: 3000,
      county: 'Nakuru',
      subCounty: 'Naivasha',
      area: 'Maiella',
      status: ListingStatus.pendingReview,
    );

    service.addListing(listing);

    expect(
      service.browse().any((item) => item.id == listing.id),
      isFalse,
    );
  });

  testWidgets(
    'non-company users are blocked from the community pre-order creation flow',
    (tester) async {
      final farmer = UserModel(
        id: 'u-farmer',
        name: 'Farmer User',
        phone: '0712345678',
        role: UserRole.farmer,
        county: 'Kiambu',
        subCounty: 'Ruiru',
        area: 'Kamakis',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthService()..state = farmer),
          ],
          child: const MaterialApp(home: CreatePreOrderScreen()),
        ),
      );

      expect(find.text('Company accounts only'), findsOneWidget);
      expect(find.textContaining('regular buy request flow'), findsOneWidget);
    },
  );
}
