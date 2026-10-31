import '../repositories/carpool_repository.dart';

/// Use-case: Book a carpool ride by its id.
class BookRideUseCase {
  final CarpoolRepository repository;

  const BookRideUseCase(this.repository);

  Future<String> call(String rideId) => repository.bookRide(rideId);
}
