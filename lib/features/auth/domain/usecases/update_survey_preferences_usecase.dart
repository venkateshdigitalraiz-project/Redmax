import '../repositories/auth_repository.dart';

class UpdateSurveyPreferencesUseCase {
  final AuthRepository repository;

  const UpdateSurveyPreferencesUseCase(this.repository);

  Future<void> call({
    List<String>? holidayWith,
    String? homeExchangeInterest,
  }) async {
    return await repository.updateSurveyPreferences(
      holidayWith: holidayWith,
      homeExchangeInterest: homeExchangeInterest,
    );
  }
}
