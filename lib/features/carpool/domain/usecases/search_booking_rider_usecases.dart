import '../entities/carpool_entities.dart';
import '../entities/rider_booking_entity.dart';
import '../repositories/search_booking_rider_repository.dart';

class GetRiderBookingsUseCase {
  final SearchBookingRiderRepository repository;
  const GetRiderBookingsUseCase(this.repository);

  Future<List<RiderBookingEntity>> call() => repository.getRiderBookings();
}

class SearchRiderRidesUseCase {
  final SearchBookingRiderRepository repository;
  const SearchRiderRidesUseCase(this.repository);

  Future<List<CarpoolRideEntity>> call({
    required String from,
    required String to,
    DateTime? date,
  }) =>
      repository.searchRides(from: from, to: to, date: date);
}

class BookRiderSeatUseCase {
  final SearchBookingRiderRepository repository;
  const BookRiderSeatUseCase(this.repository);

  Future<RiderBookingEntity> call({
    required CarpoolRideEntity ride,
    required int seats,
  }) =>
      repository.bookSeat(ride: ride, seats: seats);
}

class CancelRiderBookingUseCase {
  final SearchBookingRiderRepository repository;
  const CancelRiderBookingUseCase(this.repository);

  Future<void> call(String bookingId) =>
      repository.cancelBooking(bookingId);
}

