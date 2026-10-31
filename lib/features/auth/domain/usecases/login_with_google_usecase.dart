import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository repository;

  const LoginWithGoogleUseCase(this.repository);

  Future<UserProfile> call() async {
    return await repository.loginWithGoogle();
  }
}
