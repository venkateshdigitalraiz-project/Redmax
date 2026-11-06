import '../../features/auth/domain/entities/user_profile.dart';
import 'auth_local_storage.dart';

/// Local storage service for caching user authentication session.
class StoredLocal {
  static final StoredLocal _instance = StoredLocal._internal();
  factory StoredLocal() => _instance;
  StoredLocal._internal();

  final AuthLocalStorage _authStorage = AuthLocalStorage();
  UserProfile? _user;

  Future<void> init() async {
    await _authStorage.init();
    _user = _authStorage.getUserProfile();
  }

  Future<UserProfile?> getUser() async {
    _user ??= _authStorage.getUserProfile();
    return _user;
  }

  Future<void> saveUser(UserProfile user) async {
    _user = user;
    await _authStorage.saveUserProfile(user);
  }

  Future<void> saveAuthData(Map<String, dynamic> data) async {
    await _authStorage.saveAuthData(data);
    _user = _authStorage.getUserProfile();
  }

  Future<void> clearUser() async {
    _user = null;
    await _authStorage.clearAuthData();
  }

  Future<bool> isLoggedIn() async {
    return _user != null || _authStorage.isLoggedIn();
  }

  AuthLocalStorage get authStorage => _authStorage;
}
