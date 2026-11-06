import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/storage/storedlocal.dart';
import '../../domain/entities/user_profile.dart';

abstract class AuthLocalDataSource {
  Future<UserProfile?> getUser();
  Future<void> saveUser(UserProfile user);
  Future<void> saveWholeAuthData(Map<String, dynamic> data);
  Map<String, dynamic>? getWholeAuthData();
  String? getAccessToken();
  String? getRefreshToken();
  Future<void> clearUser();
  Future<bool> isLoggedIn();
  AuthLocalStorage get authStorage;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StoredLocal storedLocal;

  AuthLocalDataSourceImpl({StoredLocal? storedLocal})
      : storedLocal = storedLocal ?? StoredLocal();

  @override
  Future<UserProfile?> getUser() async {
    return await storedLocal.getUser();
  }

  @override
  Future<void> saveUser(UserProfile user) async {
    await storedLocal.saveUser(user);
  }

  @override
  Future<void> saveWholeAuthData(Map<String, dynamic> data) async {
    await storedLocal.saveAuthData(data);
  }

  @override
  Map<String, dynamic>? getWholeAuthData() {
    return storedLocal.authStorage.getWholeAuthData();
  }

  @override
  String? getAccessToken() {
    return storedLocal.authStorage.getAccessToken();
  }

  @override
  String? getRefreshToken() {
    return storedLocal.authStorage.getRefreshToken();
  }

  @override
  Future<void> clearUser() async {
    await storedLocal.clearUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await storedLocal.isLoggedIn();
  }

  @override
  AuthLocalStorage get authStorage => storedLocal.authStorage;
}
