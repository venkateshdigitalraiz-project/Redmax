import '../repositories/auth_repository.dart';

class SendPhoneOtpUseCase {
  final AuthRepository repository;

  const SendPhoneOtpUseCase(this.repository);

  Future<void> call(String phoneNumber) async {
    return await repository.sendPhoneOtp(phoneNumber);
  }
}
