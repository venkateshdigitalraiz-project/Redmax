import '../../domain/entities/party_entities.dart';
import '../models/party_models.dart';

abstract class PartyRemoteDataSource {
  Future<List<PartyCategoryModel>> fetchCategories();
  Future<List<PartyVenueModel>> fetchPopularVenues();
  Future<List<PartyVenueModel>> searchVenues(PartySearchVenuesParams params);
  Future<PartyVenueModel> fetchVenue(String venueId);
  Future<List<String>> fetchTimeSlots(PartyTimeSlotsParams params);
  Future<List<PartyVenueModel>> fetchFavorites();
  Future<List<PartyVenueModel>> toggleFavorite(String venueId);
  Future<PartyBookingModel> createBooking(PartyCreateBookingParams params);
  Future<List<PartyBookingModel>> fetchBookings();
  Future<void> cancelBooking(String bookingId);
}
