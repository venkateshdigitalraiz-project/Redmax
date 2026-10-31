import '../../../../core/storage/storedlocal.dart';
import '../../domain/entities/user_profile.dart';

abstract class AuthLocalDataSource {
  Future<UserProfile?> getUser();
  Future<void> saveUser(UserProfile user);
  Future<void> clearUser();
  Future<bool> isLoggedIn();
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
  Future<void> clearUser() async {
    await storedLocal.clearUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await storedLocal.isLoggedIn();
  }
}
