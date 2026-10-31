import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class ContinueAsGuestUseCase {
  final AuthRepository repository;

  const ContinueAsGuestUseCase(this.repository);

  Future<UserProfile> call() async {
    return await repository.continueAsGuest();
  }
}
