import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/search_booking_details_entity.dart';
import '../../domain/usecases/get_search_booking_details_usecase.dart';

// ── EVENTS ───────────────────────────────────────────────────────────────────

abstract class SearchBookingDetailsEvent extends Equatable {
  const SearchBookingDetailsEvent();

  @override
  List<Object?> get props => [];
}

class SearchBookingDetailsStarted extends SearchBookingDetailsEvent {
  final String rideId;

  const SearchBookingDetailsStarted(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class SearchBookingDetailsSeatsChanged extends SearchBookingDetailsEvent {
  final int seats;

  const SearchBookingDetailsSeatsChanged(this.seats);

  @override
  List<Object?> get props => [seats];
}

// ── STATE ────────────────────────────────────────────────────────────────────

class SearchBookingDetailsState extends Equatable {
  final CarpoolStatus status;
  final SearchBookingDetailsEntity? ride;
  final int selectedSeats;
  final String? errorMessage;

  const SearchBookingDetailsState({
    this.status = CarpoolStatus.initial,
    this.ride,
    this.selectedSeats = 1,
    this.errorMessage,
  });

  int get totalAmount => (ride?.pricePerSeat ?? 0) * selectedSeats;

  SearchBookingDetailsState copyWith({
    CarpoolStatus? status,
    SearchBookingDetailsEntity? ride,
    int? selectedSeats,
    String? errorMessage,
  }) {
    return SearchBookingDetailsState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, ride, selectedSeats, errorMessage];
}

// ── BLOC ─────────────────────────────────────────────────────────────────────

class SearchBookingDetailsBloc
    extends Bloc<SearchBookingDetailsEvent, SearchBookingDetailsState> {
  final GetSearchBookingDetailsUseCase getRideDetails;

  SearchBookingDetailsBloc({required this.getRideDetails})
      : super(const SearchBookingDetailsState()) {
    on<SearchBookingDetailsStarted>(_onStarted);
    on<SearchBookingDetailsSeatsChanged>(_onSeatsChanged);
  }

  Future<void> _onStarted(
    SearchBookingDetailsStarted event,
    Emitter<SearchBookingDetailsState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading, errorMessage: null));
    try {
      final details = await getRideDetails(event.rideId);
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          ride: details,
          selectedSeats: 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CarpoolStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSeatsChanged(
    SearchBookingDetailsSeatsChanged event,
    Emitter<SearchBookingDetailsState> emit,
  ) {
    if (event.seats < 1) return;
    if (state.ride != null && event.seats > state.ride!.availableSeats) return;
    emit(state.copyWith(selectedSeats: event.seats));
  }
}

