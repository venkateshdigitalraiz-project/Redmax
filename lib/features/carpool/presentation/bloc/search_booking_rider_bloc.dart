import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';

abstract class SearchBookingRiderEvent extends Equatable {
  const SearchBookingRiderEvent();
  @override
  List<Object?> get props => [];
}

class SearchBookingRiderStarted extends SearchBookingRiderEvent {
  const SearchBookingRiderStarted();
}

class SearchBookingRiderTabChanged extends SearchBookingRiderEvent {
  final int index;
  const SearchBookingRiderTabChanged(this.index);
  @override
  List<Object?> get props => [index];
}

class SearchBookingRiderSearchRequested extends SearchBookingRiderEvent {
  final String from;
  final String to;
  final DateTime? date;

  const SearchBookingRiderSearchRequested({
    required this.from,
    required this.to,
    this.date,
  });

  @override
  List<Object?> get props => [from, to, date];
}

class SearchBookingRiderBookSeatRequested extends SearchBookingRiderEvent {
  final CarpoolRideEntity ride;
  final int seats;

  const SearchBookingRiderBookSeatRequested({
    required this.ride,
    this.seats = 1,
  });

  @override
  List<Object?> get props => [ride, seats];
}

class SearchBookingRiderCancelBookingRequested extends SearchBookingRiderEvent {
  final String bookingId;
  const SearchBookingRiderCancelBookingRequested(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class SearchBookingRiderState extends Equatable {
  final CarpoolStatus status;
  final int tabIndex;
  final List<RiderBookingEntity> bookings;
  final List<CarpoolRideEntity> searchResults;
  final String from;
  final String to;
  final DateTime? date;
  final String? message;

  const SearchBookingRiderState({
    this.status = CarpoolStatus.initial,
    this.tabIndex = 0,
    this.bookings = const [],
    this.searchResults = const [],
    this.from = 'Hyderabad',
    this.to = 'Vijayawada',
    this.date,
    this.message,
  });

  List<RiderBookingEntity> get activeBookings => bookings
      .where((b) => b.status == RiderBookingStatus.confirmed)
      .toList();

  List<RiderBookingEntity> get pastBookings => bookings
      .where((b) => b.status != RiderBookingStatus.confirmed)
      .toList();

  int get activeBookingsCount => activeBookings.length;
  int get pastBookingsCount => pastBookings.length;

  SearchBookingRiderState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    List<RiderBookingEntity>? bookings,
    List<CarpoolRideEntity>? searchResults,
    String? from,
    String? to,
    DateTime? date,
    String? message,
  }) {
    return SearchBookingRiderState(
      status: status ?? this.status,
      tabIndex: tabIndex ?? this.tabIndex,
      bookings: bookings ?? this.bookings,
      searchResults: searchResults ?? this.searchResults,
      from: from ?? this.from,
      to: to ?? this.to,
      date: date ?? this.date,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tabIndex,
        bookings,
        searchResults,
        from,
        to,
        date,
        message,
      ];
}

class SearchBookingRiderBloc
    extends Bloc<SearchBookingRiderEvent, SearchBookingRiderState> {
  final GetRiderBookingsUseCase getBookings;
  final SearchRiderRidesUseCase searchRides;
  final BookRiderSeatUseCase bookSeat;
  final CancelRiderBookingUseCase cancelBooking;

  SearchBookingRiderBloc({
    required this.getBookings,
    required this.searchRides,
    required this.bookSeat,
    required this.cancelBooking,
  }) : super(const SearchBookingRiderState()) {
    on<SearchBookingRiderStarted>(_onStarted);
    on<SearchBookingRiderTabChanged>(
      (e, emit) => emit(state.copyWith(tabIndex: e.index)),
    );
    on<SearchBookingRiderSearchRequested>(_onSearch);
    on<SearchBookingRiderBookSeatRequested>(_onBookSeat);
    on<SearchBookingRiderCancelBookingRequested>(_onCancelBooking);
  }

  Future<void> _onStarted(
    SearchBookingRiderStarted event,
    Emitter<SearchBookingRiderState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final list = await getBookings();
      final initialResults = await searchRides(
        from: state.from,
        to: state.to,
        date: state.date,
      );
      emit(state.copyWith(
        status: CarpoolStatus.success,
        bookings: list,
        searchResults: initialResults,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.failure,
        message: 'Failed to load bookings: $e',
      ));
    }
  }

  Future<void> _onSearch(
    SearchBookingRiderSearchRequested event,
    Emitter<SearchBookingRiderState> emit,
  ) async {
    emit(state.copyWith(
      status: CarpoolStatus.loading,
      from: event.from,
      to: event.to,
      date: event.date,
    ));
    try {
      final results = await searchRides(
        from: event.from,
        to: event.to,
        date: event.date,
      );
      emit(state.copyWith(
        status: CarpoolStatus.success,
        searchResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.failure,
        message: 'Search failed: $e',
      ));
    }
  }

  Future<void> _onBookSeat(
    SearchBookingRiderBookSeatRequested event,
    Emitter<SearchBookingRiderState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final newBooking = await bookSeat(
        ride: event.ride,
        seats: event.seats,
      );
      final updatedBookings = [newBooking, ...state.bookings];
      emit(state.copyWith(
        status: CarpoolStatus.success,
        bookings: updatedBookings,
        tabIndex: 0, // Switch to My Bookings tab
        message: 'Ride booked successfully with ${event.ride.driverName}!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.failure,
        message: 'Booking failed: $e',
      ));
    }
  }

  Future<void> _onCancelBooking(
    SearchBookingRiderCancelBookingRequested event,
    Emitter<SearchBookingRiderState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      await cancelBooking(event.bookingId);
      final list = await getBookings();
      emit(state.copyWith(
        status: CarpoolStatus.success,
        bookings: list,
        message: 'Booking cancelled successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarpoolStatus.failure,
        message: 'Cancel failed: $e',
      ));
    }
  }
}

