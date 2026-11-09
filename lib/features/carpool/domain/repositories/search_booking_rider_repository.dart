import '../entities/carpool_entities.dart';
import '../entities/rider_booking_entity.dart';

abstract class SearchBookingRiderRepository {
  Future<List<RiderBookingEntity>> getRiderBookings();

  Future<List<CarpoolRideEntity>> searchRides({
    required String from,
    required String to,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? date,
    int? seats,
    int? radiusKm,
  });

  Future<RiderBookingEntity> bookSeat({
    required CarpoolRideEntity ride,
    required int seats,
  });

  Future<void> cancelBooking(String bookingId);
}

