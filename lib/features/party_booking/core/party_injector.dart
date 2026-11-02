import '../data/datasources/party_mock_data_source.dart';
import '../data/datasources/party_remote_data_source.dart';
import '../data/repositories/party_repository_impl.dart';
import '../domain/entities/party_entities.dart';
import '../domain/repositories/party_repository.dart';
import '../domain/usecases/party_usecases.dart';
import '../presentation/bloc/party_booking_form_bloc.dart';
import '../presentation/bloc/party_category_bloc.dart';
import '../presentation/bloc/party_favorites_bloc.dart';
import '../presentation/bloc/party_home_bloc.dart';
import '../presentation/bloc/party_my_bookings_bloc.dart';
import '../presentation/bloc/party_venue_detail_bloc.dart';
import '../presentation/bloc/party_venue_list_bloc.dart';

/// Lightweight manual DI for the Party Booking module.
/// Swap [PartyMockDataSource] for a real API data source here.
class PartyInjector {
  PartyInjector._();
  static final PartyInjector I = PartyInjector._();

  late final PartyRemoteDataSource _dataSource = PartyMockDataSource();
  late final PartyRepository _repository = PartyRepositoryImpl(_dataSource);

  late final _getCategories = PartyGetCategoriesUseCase(_repository);
  late final _getPopular = PartyGetPopularVenuesUseCase(_repository);
  late final _search = PartySearchVenuesUseCase(_repository);
  late final _getVenue = PartyGetVenueUseCase(_repository);
  late final _getSlots = PartyGetTimeSlotsUseCase(_repository);
  late final _getFavorites = PartyGetFavoritesUseCase(_repository);
  late final _toggleFavorite = PartyToggleFavoriteUseCase(_repository);
  late final _createBooking = PartyCreateBookingUseCase(_repository);
  late final _getBookings = PartyGetBookingsUseCase(_repository);
  late final _cancelBooking = PartyCancelBookingUseCase(_repository);

  PartyHomeBloc homeBloc() =>
      PartyHomeBloc(getCategories: _getCategories, getPopularVenues: _getPopular);
  PartyCategoryBloc categoryBloc() =>
      PartyCategoryBloc(getCategories: _getCategories, searchVenues: _search);
  PartyVenueListBloc venueListBloc() =>
      PartyVenueListBloc(searchVenues: _search);
  PartyVenueDetailBloc venueDetailBloc() =>
      PartyVenueDetailBloc(getVenue: _getVenue);
  PartyBookingFormBloc bookingFormBloc(PartyVenueEntity venue) =>
      PartyBookingFormBloc(
          venue: venue, getTimeSlots: _getSlots, createBooking: _createBooking);
  PartyMyBookingsBloc myBookingsBloc() => PartyMyBookingsBloc(
      getBookings: _getBookings, cancelBooking: _cancelBooking);
  PartyFavoritesBloc favoritesBloc() => PartyFavoritesBloc(
      getFavorites: _getFavorites, toggleFavorite: _toggleFavorite);
}
