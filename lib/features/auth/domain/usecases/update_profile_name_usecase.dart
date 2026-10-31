import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileNameUseCase {
  final AuthRepository repository;

  const UpdateProfileNameUseCase(this.repository);

  Future<UserProfile> call({
    required String firstName,
    required String lastName,
  }) async {
    return await repository.updateProfileName(
      firstName: firstName,
      lastName: lastName,
    );
  }
}
