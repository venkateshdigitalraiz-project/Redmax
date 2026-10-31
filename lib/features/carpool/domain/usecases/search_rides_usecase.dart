import '../entities/carpool_ride.dart';
import '../repositories/carpool_repository.dart';

/// Use-case: Search carpool rides by query string (origin / destination).
class SearchRidesUseCase {
  final CarpoolRepository repository;

  const SearchRidesUseCase(this.repository);

  Future<List<CarpoolRide>> call(String query) => repository.searchRides(query);
}
