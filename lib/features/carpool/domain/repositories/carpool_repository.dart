import '../entities/carpool_ride.dart';

/// Abstract repository contract for Carpool feature.
abstract class CarpoolRepository {
  /// Fetches all available carpool rides.
  Future<List<CarpoolRide>> getAvailableRides();

  /// Searches rides by [query] (matches origin or destination).
  Future<List<CarpoolRide>> searchRides(String query);

  /// Books the ride with [rideId]. Returns the booked ride id on success.
  Future<String> bookRide(String rideId);
}
