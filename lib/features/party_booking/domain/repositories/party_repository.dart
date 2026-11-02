import '../entities/party_entities.dart';

/// Contract implemented by the data layer.
abstract class PartyRepository {
  Future<List<PartyCategoryEntity>> getCategories();
  Future<List<PartyVenueEntity>> getPopularVenues();
  Future<List<PartyVenueEntity>> searchVenues(PartySearchVenuesParams params);
  Future<PartyVenueEntity> getVenue(String venueId);
  Future<List<String>> getTimeSlots(PartyTimeSlotsParams params);
  Future<List<PartyVenueEntity>> getFavorites();
  Future<List<PartyVenueEntity>> toggleFavorite(String venueId);
  Future<PartyBookingEntity> createBooking(PartyCreateBookingParams params);
  Future<List<PartyBookingEntity>> getBookings();
  Future<void> cancelBooking(String bookingId);
}
