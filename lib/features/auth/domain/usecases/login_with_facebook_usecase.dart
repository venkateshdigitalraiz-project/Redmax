import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class LoginWithFacebookUseCase {
  final AuthRepository repository;

  const LoginWithFacebookUseCase(this.repository);

  Future<UserProfile> call() async {
    return await repository.loginWithFacebook();
  }
}
