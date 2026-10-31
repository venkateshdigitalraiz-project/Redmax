import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  final AuthRepository repository;

  const RegisterWithEmailUseCase(this.repository);

  Future<UserProfile> call({
    required String email,
    required String firstName,
    required String lastName,
    required bool optOutMarketing,
  }) async {
    return await repository.registerWithEmail(
      email: email,
      firstName: firstName,
      lastName: lastName,
      optOutMarketing: optOutMarketing,
    );
  }
}
