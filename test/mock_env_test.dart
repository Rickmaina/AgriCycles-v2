import 'package:agricycles/core/network/api_config.dart';
import 'package:agricycles/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('USE_MOCK compile-time flag enables the mock auth path', () async {
    expect(ApiConfig.useMock, isTrue,
        reason: 'The build must define USE_MOCK=true at compile time.');

    final service = AuthService();
    final user = await service.login(
      phone: '0712345678',
      password: 'secret',
    );

    expect(user.name, 'Grace Wanjiku');
    expect(user.phone, '0712345678');
  });
}
