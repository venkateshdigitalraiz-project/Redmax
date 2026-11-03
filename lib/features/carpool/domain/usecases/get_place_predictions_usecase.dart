import '../entities/place_prediction_entity.dart';
import '../repositories/places_repository.dart';

class GetPlacePredictionsUseCase {
  final PlacesRepository repository;

  const GetPlacePredictionsUseCase(this.repository);

  Future<List<PlacePredictionEntity>> call(String query) {
    return repository.getPlacePredictions(query);
  }
}

