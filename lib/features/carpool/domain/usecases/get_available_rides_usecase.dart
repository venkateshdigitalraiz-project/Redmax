import '../entities/carpool_ride.dart';
import '../repositories/carpool_repository.dart';

/// Use-case: Fetch all available carpool rides.
class GetAvailableRidesUseCase {
  final CarpoolRepository repository;

  const GetAvailableRidesUseCase(this.repository);

  Future<List<CarpoolRide>> call() => repository.getAvailableRides();
}
