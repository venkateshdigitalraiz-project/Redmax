import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_filter.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_ride.dart';
import 'package:pathway/features/carpool/domain/usecases/book_ride_usecase.dart';
import 'package:pathway/features/carpool/domain/usecases/get_available_rides_usecase.dart';
import 'package:pathway/features/carpool/domain/usecases/search_rides_usecase.dart';
import 'carpool_event.dart';
import 'carpool_state.dart';

/// BLoC responsible for the entire carpool feature flow.
class CarpoolBloc extends Bloc<CarpoolEvent, CarpoolState> {
  final GetAvailableRidesUseCase getAvailableRidesUseCase;
  final SearchRidesUseCase searchRidesUseCase;
  final BookRideUseCase bookRideUseCase;

  CarpoolBloc({
    required this.getAvailableRidesUseCase,
    required this.searchRidesUseCase,
    required this.bookRideUseCase,
  }) : super(const CarpoolState()) {
    on<LoadCarpoolRidesEvent>(_onLoadRides);
    on<SearchCarpoolRidesEvent>(_onSearchRides);
    on<ApplyCarpoolFilterEvent>(_onApplyFilter);
    on<SelectCarpoolRideEvent>(_onSelectRide);
    on<BookCarpoolRideEvent>(_onBookRide);
    on<CarpoolSeatCountChangedEvent>(_onSeatCountChanged);
    on<ResetCarpoolBookingEvent>(_onResetBooking);
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLoadRides(
    LoadCarpoolRidesEvent event,
    Emitter<CarpoolState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading, clearError: true));
    try {
      final rides = await getAvailableRidesUseCase();
      final filtered = _applyFilter(rides, state.filter);
      emit(state.copyWith(
        status: CarpoolStatus.loaded,
        rides: rides,
        filteredRides: filtered,
        searchQuery: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchRides(
    SearchCarpoolRidesEvent event,
    Emitter<CarpoolState> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(
      status: CarpoolStatus.searching,
      searchQuery: query,
      clearError: true,
    ));
    try {
      if (query.isEmpty) {
        final filtered = _applyFilter(state.rides, state.filter);
        emit(state.copyWith(
          status: CarpoolStatus.loaded,
          filteredRides: filtered,
        ));
      } else {
        final results = await searchRidesUseCase(query);
        final filtered = _applyFilter(results, state.filter);
        emit(state.copyWith(
          status: CarpoolStatus.loaded,
          filteredRides: filtered,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onApplyFilter(
    ApplyCarpoolFilterEvent event,
    Emitter<CarpoolState> emit,
  ) {
    final source =
        state.searchQuery.isEmpty ? state.rides : state.filteredRides;
    final filtered = _applyFilter(source, event.filter);
    emit(state.copyWith(
      filter: event.filter,
      filteredRides: filtered,
      status: CarpoolStatus.loaded,
    ));
  }

  void _onSelectRide(
    SelectCarpoolRideEvent event,
    Emitter<CarpoolState> emit,
  ) {
    emit(state.copyWith(
      selectedRide: event.ride,
      selectedSeats: 1,
      clearBookedRideId: true,
      clearError: true,
    ));
  }

  Future<void> _onBookRide(
    BookCarpoolRideEvent event,
    Emitter<CarpoolState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.booking, clearError: true));
    try {
      final bookedId = await bookRideUseCase(event.rideId);
      emit(state.copyWith(
        status: CarpoolStatus.booked,
        bookedRideId: bookedId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSeatCountChanged(
    CarpoolSeatCountChangedEvent event,
    Emitter<CarpoolState> emit,
  ) {
    emit(state.copyWith(selectedSeats: event.seats));
  }

  void _onResetBooking(
    ResetCarpoolBookingEvent event,
    Emitter<CarpoolState> emit,
  ) {
    emit(state.copyWith(
      status: CarpoolStatus.loaded,
      clearBookedRideId: true,
      clearSelectedRide: true,
      clearError: true,
      selectedSeats: 1,
    ));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<CarpoolRide> _applyFilter(
    List<CarpoolRide> rides,
    CarpoolFilter filter,
  ) {
    List<CarpoolRide> result = List<CarpoolRide>.from(rides);

    // Min seats filter
    result = result
        .where((r) => r.seatsAvailable >= filter.minSeats)
        .toList();

    // Max price filter
    if (filter.maxPrice != null) {
      result =
          result.where((r) => r.pricePerSeat <= filter.maxPrice!).toList();
    }

    // Sort
    switch (filter.sortBy) {
      case CarpoolSortBy.priceAsc:
        result.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
      case CarpoolSortBy.priceDsc:
        result.sort((a, b) => b.pricePerSeat.compareTo(a.pricePerSeat));
      case CarpoolSortBy.earliest:
        result.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      case CarpoolSortBy.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return result;
  }
}
