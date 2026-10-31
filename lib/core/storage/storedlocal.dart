import '../../features/auth/domain/entities/user_profile.dart';

/// Local storage service for caching user authentication session.
class StoredLocal {
  static final StoredLocal _instance = StoredLocal._internal();
  factory StoredLocal() => _instance;
  StoredLocal._internal();

  UserProfile? _user;

  Future<void> init() async {
    // Initializes the default user session
    _user ??= const UserProfile(
      id: 'usr_venkatesh_1',
      firstName: 'Venkatesh',
      lastName: 'Kumar',
      email: 'venkatesh@pathway.com',
      phoneNumber: '+91 9876543210',
      authProvider: 'phone',
      optOutMarketing: false,
    );
  }

  Future<UserProfile?> getUser() async {
    return _user;
  }

  Future<void> saveUser(UserProfile user) async {
    _user = user;
  }

  Future<void> clearUser() async {
    _user = null;
  }

  Future<bool> isLoggedIn() async {
    return _user != null;
  }
}

