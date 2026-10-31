import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  Future<UserProfile?> call() async {
    return await repository.getCurrentUser();
  }
}
