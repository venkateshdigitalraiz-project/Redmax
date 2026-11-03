import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_data_source.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesRemoteDataSource remoteDataSource;

  PlacesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PlacePredictionEntity>> getPlacePredictions(String query) async {
    return remoteDataSource.getPlacePredictions(query);
  }
}

