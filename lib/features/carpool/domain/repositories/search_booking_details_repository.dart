import '../entities/search_booking_details_entity.dart';

/// Abstract contract for Ride Details
abstract class SearchBookingDetailsRepository {
  Future<SearchBookingDetailsEntity> getRideDetails(String rideId);
}

