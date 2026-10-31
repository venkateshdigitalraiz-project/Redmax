import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<UserProfile?> getCurrentUser() async {
    return await localDataSource.getUser();
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    // Simulates sending 4-digit OTP SMS to the phone number
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<UserProfile> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    // Any valid 4-digit OTP grants entry as authenticated BlaBlaCar user
    await Future.delayed(const Duration(milliseconds: 300));

    final user = UserProfile(
      id: 'usr_${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}',
      firstName: 'Venkatesh',
      lastName: '',
      email: '$phoneNumber@pathway.com',
      phoneNumber: phoneNumber,
      authProvider: 'phone',
      optOutMarketing: false,
    );
    await localDataSource.saveUser(user);
    return user;
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
    await localDataSource.clearUser();
  }
}
