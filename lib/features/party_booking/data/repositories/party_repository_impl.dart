import '../../domain/entities/party_entities.dart';
import '../../domain/repositories/party_repository.dart';
import '../datasources/party_remote_data_source.dart';

class PartyRepositoryImpl implements PartyRepository {
  const PartyRepositoryImpl(this._remote);
  final PartyRemoteDataSource _remote;

  @override
  Future<List<PartyCategoryEntity>> getCategories() => _remote.fetchCategories();

  @override
  Future<List<PartyVenueEntity>> getPopularVenues() =>
      _remote.fetchPopularVenues();

  @override
  Future<List<PartyVenueEntity>> searchVenues(PartySearchVenuesParams params) =>
      _remote.searchVenues(params);

  @override
  Future<PartyVenueEntity> getVenue(String venueId) =>
      _remote.fetchVenue(venueId);

  @override
  Future<List<String>> getTimeSlots(PartyTimeSlotsParams params) =>
      _remote.fetchTimeSlots(params);

  @override
  Future<List<PartyVenueEntity>> getFavorites() => _remote.fetchFavorites();

  @override
  Future<List<PartyVenueEntity>> toggleFavorite(String venueId) =>
      _remote.toggleFavorite(venueId);

  @override
  Future<PartyBookingEntity> createBooking(PartyCreateBookingParams params) =>
      _remote.createBooking(params);

  @override
  Future<List<PartyBookingEntity>> getBookings() => _remote.fetchBookings();

  @override
  Future<void> cancelBooking(String bookingId) =>
      _remote.cancelBooking(bookingId);
}
