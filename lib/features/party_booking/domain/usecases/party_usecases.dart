import '../entities/party_entities.dart';
import '../repositories/party_repository.dart';
import 'party_usecase.dart';

class PartyGetCategoriesUseCase
    implements PartyUseCase<List<PartyCategoryEntity>, PartyNoParams> {
  const PartyGetCategoriesUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyCategoryEntity>> call(PartyNoParams params) =>
      _repository.getCategories();
}

class PartyGetPopularVenuesUseCase
    implements PartyUseCase<List<PartyVenueEntity>, PartyNoParams> {
  const PartyGetPopularVenuesUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyVenueEntity>> call(PartyNoParams params) =>
      _repository.getPopularVenues();
}

class PartySearchVenuesUseCase
    implements PartyUseCase<List<PartyVenueEntity>, PartySearchVenuesParams> {
  const PartySearchVenuesUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyVenueEntity>> call(PartySearchVenuesParams params) =>
      _repository.searchVenues(params);
}

class PartyGetVenueUseCase implements PartyUseCase<PartyVenueEntity, String> {
  const PartyGetVenueUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<PartyVenueEntity> call(String venueId) =>
      _repository.getVenue(venueId);
}

class PartyGetTimeSlotsUseCase
    implements PartyUseCase<List<String>, PartyTimeSlotsParams> {
  const PartyGetTimeSlotsUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<String>> call(PartyTimeSlotsParams params) =>
      _repository.getTimeSlots(params);
}

class PartyGetFavoritesUseCase
    implements PartyUseCase<List<PartyVenueEntity>, PartyNoParams> {
  const PartyGetFavoritesUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyVenueEntity>> call(PartyNoParams params) =>
      _repository.getFavorites();
}

class PartyToggleFavoriteUseCase
    implements PartyUseCase<List<PartyVenueEntity>, String> {
  const PartyToggleFavoriteUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyVenueEntity>> call(String venueId) =>
      _repository.toggleFavorite(venueId);
}

class PartyCreateBookingUseCase
    implements PartyUseCase<PartyBookingEntity, PartyCreateBookingParams> {
  const PartyCreateBookingUseCase(this._repository);
  final PartyRepository _repository;

  @override
  Future<PartyBookingEntity> call(PartyCreateBookingParams p) {
    if (p.guestName.trim().length < 2) {
      throw const PartyFailure('Enter your full name.');
    }
    if (p.phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      throw const PartyFailure('Enter a valid 10-digit phone number.');
    }
    if (p.guests < 1) {
      throw const PartyFailure('Add at least one guest.');
    }
    return _repository.createBooking(p);
  }
}

class PartyGetBookingsUseCase
    implements PartyUseCase<List<PartyBookingEntity>, PartyNoParams> {
  const PartyGetBookingsUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<List<PartyBookingEntity>> call(PartyNoParams params) =>
      _repository.getBookings();
}

class PartyCancelBookingUseCase implements PartyUseCase<void, String> {
  const PartyCancelBookingUseCase(this._repository);
  final PartyRepository _repository;
  @override
  Future<void> call(String bookingId) => _repository.cancelBooking(bookingId);
}
