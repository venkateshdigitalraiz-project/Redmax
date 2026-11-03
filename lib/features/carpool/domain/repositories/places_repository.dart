import '../entities/place_prediction_entity.dart';

abstract class PlacesRepository {
  Future<List<PlacePredictionEntity>> getPlacePredictions(String query);
}

