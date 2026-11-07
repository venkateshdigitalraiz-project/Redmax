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
    try {
      await _prefs?.reload();
    } catch (_) {}
    return _prefs!;
  }

  SharedPreferences? get preferences => _prefs;

  /// Store the whole data payload from the login response
  Future<void> saveAuthData(Map<String, dynamic> data) async {
    final sp = _prefs ?? await init();

    // 1. Store whole response data as JSON
    await sp.setString(keyWholeAuthData, jsonEncode(data));

    // Handle nested payload if data is wrapped in {"data": { ... }}
    Map<String, dynamic> payload = data;
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      payload = data['data'] as Map<String, dynamic>;
    }

    // 2. Store tokens and expiration fields
    final rawToken = payload['token'] ?? data['token'];
    final rawAccessToken = payload['accessToken'] ?? data['accessToken'] ?? rawToken;
    final rawRefreshToken = payload['refreshToken'] ?? data['refreshToken'];
    final rawExpiresIn = payload['expiresIn'] ?? data['expiresIn'];
    final rawRefreshExpiresAt = payload['refreshExpiresAt'] ?? data['refreshExpiresAt'];

    if (rawToken != null) {
      final t = _cleanBearer(rawToken.toString());
      await sp.setString(keyToken, t);
      await sp.setString('token', t);
    }
    if (rawAccessToken != null) {
      final at = _cleanBearer(rawAccessToken.toString());
      await sp.setString(keyAccessToken, at);
      await sp.setString('accessToken', at);
      await sp.setString('access_token', at);
    }
    if (rawRefreshToken != null) {
      final rt = _cleanBearer(rawRefreshToken.toString());
      await sp.setString(keyRefreshToken, rt);
      await sp.setString('refreshToken', rt);
      await sp.setString('refresh_token', rt);
    }
    if (rawExpiresIn != null) {
      await sp.setString(keyExpiresIn, rawExpiresIn.toString());
    }
    if (rawRefreshExpiresAt != null) {
      await sp.setString(keyRefreshExpiresAt, rawRefreshExpiresAt.toString());
    }

    // 3. Store user details
    final userMap = payload['user'] ?? data['user'];
    if (userMap is Map<String, dynamic>) {
      await sp.setString(keyUserJson, jsonEncode(userMap));
    }

    debugPrint('\n==================== [LOCAL STORAGE: AUTH DATA STORED] ====================');
    debugPrint('USER_ID: ${userMap?['id'] ?? userMap?['_id']}');
    debugPrint('USER_NAME: ${userMap?['name']}');
    debugPrint('USER_PHONE: ${userMap?['phone']}');
    debugPrint('TOKEN: $rawToken');
    debugPrint('ACCESS_TOKEN: $rawAccessToken');
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
    return _extractToken(_prefs);
  }

  /// Retrieve the accessToken synchronously
  String? getAccessToken() {
    return _extractToken(_prefs);
  }

  /// Retrieve the accessToken asynchronously ensuring prefs are initialized and reloaded
  Future<String?> getAccessTokenAsync() async {
    final sp = await init();
    return _extractToken(sp);
  }

  String? _extractToken(SharedPreferences? sp) {
    if (sp == null) return null;

    // 1. Direct candidate keys
    const candidateKeys = [
      keyAccessToken, // 'auth_access_token'
      keyToken,       // 'auth_token'
      'accessToken',
      'token',
      'access_token',
      'authToken',
      'jwt',
      'jwt_token',
      'bearer_token',
    ];

    for (final key in candidateKeys) {
      final val = sp.getString(key);
      if (val != null && val.trim().isNotEmpty && val != 'null') {
        return _cleanBearer(val);
      }
    }

    // 2. Check in whole auth data JSON ('auth_whole_data')
    final rawWhole = sp.getString(keyWholeAuthData);
    if (rawWhole != null && rawWhole.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWhole);
        if (decoded is Map<String, dynamic>) {
          final t = decoded['accessToken'] ??
              decoded['token'] ??
              decoded['data']?['accessToken'] ??
              decoded['data']?['token'];
          if (t != null && t.toString().trim().isNotEmpty && t.toString() != 'null') {
            return _cleanBearer(t.toString());
          }
        }
      } catch (_) {}
    }

    // 3. Check in user JSON ('auth_user_json')
    final rawUser = sp.getString(keyUserJson);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map<String, dynamic>) {
          final t = decoded['token'] ?? decoded['accessToken'];
          if (t != null && t.toString().trim().isNotEmpty && t.toString() != 'null') {
            return _cleanBearer(t.toString());
          }
        }
      } catch (_) {}
    }

    return null;
  }

  String _cleanBearer(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
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
    await sp.clear();
    debugPrint('\n==================== [LOCAL STORAGE: AUTH DATA CLEARED] ====================');
    debugPrint('All authentication keys and SharedPreferences have been wiped successfully.');
    debugPrint('============================================================================\n');
  }
}

