import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_profile.dart';

/// Service for persisting authentication session data, tokens, and user details
/// using SharedPreferences.
class AuthLocalStorage {
  static final AuthLocalStorage _instance = AuthLocalStorage._internal();
  factory AuthLocalStorage() => _instance;
  AuthLocalStorage._internal();

  static const String keyToken = 'auth_token';
  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyExpiresIn = 'auth_expires_in';
  static const String keyRefreshExpiresAt = 'auth_refresh_expires_at';
  static const String keyUserJson = 'auth_user_json';
  static const String keyWholeAuthData = 'auth_whole_data';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  Future<SharedPreferences> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  SharedPreferences? get preferences => _prefs;

  /// Store the whole data payload from the login response
  ///
  /// Expected data structure:
  /// {
  ///   "user": {
  ///     "id": "...",
  ///     "name": "...",
  ///     "email": "...",
  ///     "phone": "...",
  ///     "role": "..."
  ///   },
  ///   "token": "...",
  ///   "accessToken": "...",
  ///   "refreshToken": "...",
  ///   "expiresIn": "15m",
  ///   "refreshExpiresAt": "..."
  /// }
  Future<void> saveAuthData(Map<String, dynamic> data) async {
    final sp = _prefs ?? await init();

    // 1. Store whole response data as JSON
    await sp.setString(keyWholeAuthData, jsonEncode(data));

    // 2. Store tokens and expiration fields
    if (data['token'] != null) {
      await sp.setString(keyToken, data['token'].toString());
    }
    if (data['accessToken'] != null) {
      await sp.setString(keyAccessToken, data['accessToken'].toString());
    }
    if (data['refreshToken'] != null) {
      await sp.setString(keyRefreshToken, data['refreshToken'].toString());
    }
    if (data['expiresIn'] != null) {
      await sp.setString(keyExpiresIn, data['expiresIn'].toString());
    }
    if (data['refreshExpiresAt'] != null) {
      await sp.setString(keyRefreshExpiresAt, data['refreshExpiresAt'].toString());
    }

    // 3. Store user details
    if (data['user'] is Map<String, dynamic>) {
      await sp.setString(keyUserJson, jsonEncode(data['user']));
    }

    debugPrint('\n==================== [LOCAL STORAGE: AUTH DATA STORED] ====================');
    debugPrint('USER_ID: ${data['user']?['id'] ?? data['user']?['_id']}');
    debugPrint('USER_NAME: ${data['user']?['name']}');
    debugPrint('USER_PHONE: ${data['user']?['phone']}');
    debugPrint('USER_ROLE: ${data['user']?['role']}');
    debugPrint('TOKEN: ${data['token']}');
    debugPrint('ACCESS_TOKEN: ${data['accessToken']}');
    debugPrint('REFRESH_TOKEN: ${data['refreshToken']}');
    debugPrint('EXPIRES_IN: ${data['expiresIn']}');
    debugPrint('REFRESH_EXPIRES_AT: ${data['refreshExpiresAt']}');
    debugPrint('SHARED_PREFERENCES: Whole response map saved to key "$keyWholeAuthData"');
    debugPrint('============================================================================\n');
  }

  /// Store or update UserProfile
  Future<void> saveUserProfile(UserProfile user) async {
    final sp = _prefs ?? await init();
    await sp.setString(keyUserJson, jsonEncode(user.toJson()));
    debugPrint('[LOCAL STORAGE: USER PROFILE PERSISTED] ${user.id} - ${user.fullName} (${user.role})');
  }

  /// Retrieve the token
  String? getToken() {
    return _prefs?.getString(keyToken);
  }

  /// Retrieve the accessToken
  String? getAccessToken() {
    return _prefs?.getString(keyAccessToken) ?? _prefs?.getString(keyToken);
  }

  /// Retrieve the refreshToken
  String? getRefreshToken() {
    return _prefs?.getString(keyRefreshToken);
  }

  /// Retrieve the expiresIn
  String? getExpiresIn() {
    return _prefs?.getString(keyExpiresIn);
  }

  /// Retrieve the refreshExpiresAt
  String? getRefreshExpiresAt() {
    return _prefs?.getString(keyRefreshExpiresAt);
  }

  /// Retrieve the raw user data map
  Map<String, dynamic>? getUserData() {
    final raw = _prefs?.getString(keyUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Retrieve the UserProfile object
  UserProfile? getUserProfile() {
    final userMap = getUserData();
    if (userMap == null) return null;
    try {
      String firstName = userMap['firstName'] as String? ?? '';
      String lastName = userMap['lastName'] as String? ?? '';
      if (firstName.isEmpty && userMap['name'] != null) {
        final fullName = (userMap['name'] as String).trim();
        final parts = fullName.split(' ');
        firstName = parts.isNotEmpty ? parts.first : fullName;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      return UserProfile(
        id: userMap['id']?.toString() ??
            userMap['_id']?.toString() ??
            'usr_${DateTime.now().millisecondsSinceEpoch}',
        firstName: firstName.isNotEmpty ? firstName : 'User',
        lastName: lastName,
        email: userMap['email']?.toString() ?? '',
        phoneNumber: userMap['phone']?.toString() ??
            userMap['phoneNumber']?.toString() ??
            '',
        role: userMap['role']?.toString() ?? 'user',
        authProvider: userMap['authProvider']?.toString() ?? 'phone',
      );
    } catch (_) {
      return null;
    }
  }

  /// Retrieve the whole data object stored during login
  Map<String, dynamic>? getWholeAuthData() {
    final raw = _prefs?.getString(keyWholeAuthData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Check whether an authenticated session exists
  bool isLoggedIn() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored authentication data
  Future<void> clearAuthData() async {
    final sp = _prefs ?? await init();
    await sp.remove(keyToken);
    await sp.remove(keyAccessToken);
    await sp.remove(keyRefreshToken);
    await sp.remove(keyExpiresIn);
    await sp.remove(keyRefreshExpiresAt);
    await sp.remove(keyUserJson);
    await sp.remove(keyWholeAuthData);
  }
}

