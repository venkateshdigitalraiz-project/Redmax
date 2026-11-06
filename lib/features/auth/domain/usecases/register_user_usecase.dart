import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);

  Future<UserProfile> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) {
    return repository.registerUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
  }
}

