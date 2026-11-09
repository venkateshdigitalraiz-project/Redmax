import '../entities/search_booking_details_entity.dart';
import '../repositories/search_booking_details_repository.dart';

/// UseCase to fetch full ride details for a specific ride ID
class GetSearchBookingDetailsUseCase {
  final SearchBookingDetailsRepository repository;

  const GetSearchBookingDetailsUseCase(this.repository);

  Future<SearchBookingDetailsEntity> call(String rideId) {
    return repository.getRideDetails(rideId);
  }
}

