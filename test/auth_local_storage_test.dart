import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/storage/storedlocal.dart';
import 'package:pathway/features/auth/data/models/auth_response_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthLocalStorage Tests', () {
    test('saveAuthData stores tokens, user, and whole data properly', () async {
      final storage = AuthLocalStorage();
      await storage.init();

      final responseMap = {
        'status': 'success',
        'message': 'Phone OTP login successful',
        'data': {
          'user': {
            'id': '6aeda0197b77336365780820',
            'name': 'John Doe',
            'email': 'johndoe@example.com',
            'phone': '+919876543210',
            'role': 'user'
          },
          'token': 'mock_token_123',
          'accessToken': 'mock_access_token_123',
          'refreshToken': 'mock_refresh_token_456',
          'expiresIn': '15m',
          'refreshExpiresAt': '2026-12-06T11:27:27.140Z'
        }
      };

      final authModel = AuthResponseModel.fromJson(responseMap);
      expect(authModel.token, 'mock_token_123');
      expect(authModel.accessToken, 'mock_access_token_123');
      expect(authModel.refreshToken, 'mock_refresh_token_456');
      expect(authModel.expiresIn, '15m');
      expect(authModel.user.id, '6aeda0197b77336365780820');
      expect(authModel.user.firstName, 'John');
      expect(authModel.user.lastName, 'Doe');
      expect(authModel.user.email, 'johndoe@example.com');
      expect(authModel.user.phoneNumber, '+919876543210');
      expect(authModel.user.role, 'user');

      // Save via AuthLocalStorage
      await storage.saveAuthData(authModel.rawData);

      // Verify retrieval
      expect(storage.getToken(), 'mock_token_123');
      expect(storage.getAccessToken(), 'mock_access_token_123');
      expect(storage.getRefreshToken(), 'mock_refresh_token_456');
      expect(storage.getExpiresIn(), '15m');
      expect(storage.getRefreshExpiresAt(), '2026-12-06T11:27:27.140Z');
      expect(storage.isLoggedIn(), isTrue);

      final userProfile = storage.getUserProfile();
      expect(userProfile, isNotNull);
      expect(userProfile!.id, '6aeda0197b77336365780820');
      expect(userProfile.firstName, 'John');
      expect(userProfile.lastName, 'Doe');
      expect(userProfile.phoneNumber, '+919876543210');
      expect(userProfile.role, 'user');

      final wholeData = storage.getWholeAuthData();
      expect(wholeData, isNotNull);
      expect(wholeData!['refreshToken'], 'mock_refresh_token_456');

      // Test clear
      await storage.clearAuthData();
      expect(storage.isLoggedIn(), isFalse);
      expect(storage.getToken(), isNull);
      expect(storage.getUserProfile(), isNull);
    });

    test('StoredLocal integrates AuthLocalStorage seamlessly', () async {
      final storedLocal = StoredLocal();
      await storedLocal.init();

      final data = {
        'user': {
          'id': '6aeda0197b77336365780820',
          'name': 'John Doe',
          'email': 'johndoe@example.com',
          'phone': '+919876543210',
          'role': 'user'
        },
        'token': 'tok_abc',
        'accessToken': 'acc_abc',
        'refreshToken': 'ref_abc',
        'expiresIn': '15m',
        'refreshExpiresAt': '2026-12-06T11:27:27.140Z'
      };

      await storedLocal.saveAuthData(data);
      expect(await storedLocal.isLoggedIn(), isTrue);

      final user = await storedLocal.getUser();
      expect(user, isNotNull);
      expect(user!.firstName, 'John');
      expect(user.phoneNumber, '+919876543210');
    });
  });
}

