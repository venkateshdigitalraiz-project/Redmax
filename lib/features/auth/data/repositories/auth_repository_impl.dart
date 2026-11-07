import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    AuthRemoteDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl();

  @override
  Future<UserProfile?> getCurrentUser() async {
    return await localDataSource.getUser();
  }

  @override
  Future<UserProfile> getUserProfile() async {
    final token = localDataSource.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final user =
            await remoteDataSource.getUserProfile(accessToken: token);
        await localDataSource.saveUser(user);
        return user;
      } catch (e) {
        final cached = await localDataSource.getUser();
        if (cached != null) return cached;
        rethrow;
      }
    }
    final cached = await localDataSource.getUser();
    if (cached != null) return cached;
    throw Exception('No active session or access token found');
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    await remoteDataSource.sendOtp(phoneNumber);
  }

  @override
  Future<void> resendPhoneOtp(String phoneNumber) async {
    await remoteDataSource.resendOtp(phoneNumber);
  }

  @override
  Future<UserProfile> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final authResponse = await remoteDataSource.verifyOtp(
      phone: phoneNumber,
      otp: otp,
    );
    // Store whole response data in SharedPreferences via AuthLocalStorage
    await localDataSource.saveWholeAuthData(authResponse.rawData);
    await localDataSource.saveUser(authResponse.user);
    return authResponse.user;
  }

  @override
  Future<UserProfile> loginWithFacebook() async {
    final user = const UserProfile(
      id: 'fb_user_101',
      firstName: 'Venkatesh',
      lastName: 'Kumar',
      email: 'venkatesh@facebook.com',
      phoneNumber: '+91 9876543210',
      authProvider: 'facebook',
      optOutMarketing: false,
    );
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> loginWithGoogle() async {
    final user = const UserProfile(
      id: 'google_user_102',
      firstName: 'Venkatesh',
      lastName: '',
      email: 'venkatesh@gmail.com',
      phoneNumber: '+91 9876543210',
      authProvider: 'google',
      optOutMarketing: false,
    );
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> registerWithEmail({
    required String email,
    required String firstName,
    required String lastName,
    required bool optOutMarketing,
  }) async {
    final user = UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName.trim().isEmpty ? 'Venkatesh' : firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phoneNumber: '+91 9876543210',
      authProvider: 'email',
      optOutMarketing: optOutMarketing,
    );
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    final user = await remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    // User is registered on backend. After registration success,
    // user goes to AuthWelcomePage to sign in, so do not persist active session yet.
    return user;
  }

  @override
  Future<UserProfile> updateProfileName({
    required String firstName,
    required String lastName,
  }) async {
    final currentUser = await localDataSource.getUser();
    final updated = UserProfile(
      id: currentUser?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName.trim().isEmpty ? 'Venkatesh' : firstName.trim(),
      lastName: lastName.trim(),
      email: currentUser?.email ?? 'rider@pathway.com',
      phoneNumber: currentUser?.phoneNumber ?? '+91 9876543210',
      authProvider: currentUser?.authProvider ?? 'phone',
      optOutMarketing: currentUser?.optOutMarketing ?? false,
    );
    await localDataSource.saveUser(updated);
    return updated;
  }

  @override
  Future<UserProfile> continueAsGuest() async {
    const guest = UserProfile(
      id: 'guest_user',
      firstName: 'Guest',
      lastName: 'Traveler',
      email: 'guest@pathway.com',
      authProvider: 'guest',
    );
    await localDataSource.saveUser(guest);
    return guest;
  }

  @override
  Future<void> updateSurveyPreferences({
    List<String>? holidayWith,
    String? homeExchangeInterest,
  }) async {
    final current = await localDataSource.getUser();
    if (current != null) {
      final updated = current.copyWith(
        holidayWith: holidayWith ?? current.holidayWith,
        homeExchangeInterest: homeExchangeInterest ?? current.homeExchangeInterest,
      );
      await localDataSource.saveUser(updated);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = localDataSource.getRefreshToken() ??
        localDataSource.authStorage.getRefreshToken() ??
        localDataSource.getAccessToken() ??
        '';
    await remoteDataSource.logout(refreshToken: refreshToken);
    await localDataSource.clearUser();
  }
}
