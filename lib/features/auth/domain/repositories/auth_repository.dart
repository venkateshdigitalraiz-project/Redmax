import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> getUserProfile();
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<void> resendPhoneOtp(String phoneNumber);
  Future<UserProfile> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });
  Future<UserProfile> loginWithFacebook();
  Future<UserProfile> loginWithGoogle();
  Future<UserProfile> registerWithEmail({
    required String email,
    required String firstName,
    required String lastName,
    required bool optOutMarketing,
  });
  Future<UserProfile> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  });
  Future<UserProfile> updateProfileName({
    required String firstName,
    required String lastName,
  });
  Future<UserProfile> continueAsGuest();
  Future<void> updateSurveyPreferences({
    List<String>? holidayWith,
    String? homeExchangeInterest,
  });
  Future<void> logout();
}
