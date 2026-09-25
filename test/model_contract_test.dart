import 'package:agricycles/core/constants/enums.dart';
import 'package:agricycles/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contract compatibility', () {
    test('listing statuses include pending review', () {
      expect(ListingStatus.values, contains(ListingStatus.pendingReview));
    });

    test('user model accepts a farm scale value', () {
      const user = UserModel(
        id: 'u1',
        name: 'Test User',
        phone: '0712345678',
        role: UserRole.farmer,
        farmScale: 'small_scale',
      );

      expect(user.farmScale, 'small_scale');
    });
  });
}
