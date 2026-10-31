import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase {
  final AuthRepository repository;

  const VerifyPhoneOtpUseCase(this.repository);

  Future<UserProfile> call({
    required String phoneNumber,
    required String otp,
  }) async {
    return await repository.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      otp: otp,
    );
  }
}
