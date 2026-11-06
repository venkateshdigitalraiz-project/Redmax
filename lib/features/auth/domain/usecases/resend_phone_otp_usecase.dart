import '../repositories/auth_repository.dart';

class ResendPhoneOtpUseCase {
  final AuthRepository repository;

  ResendPhoneOtpUseCase(this.repository);

  Future<void> call(String phoneNumber) {
    return repository.resendPhoneOtp(phoneNumber);
  }
}

