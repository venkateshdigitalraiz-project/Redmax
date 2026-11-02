import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecase.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyMyBookingsEvent extends Equatable {
  const PartyMyBookingsEvent();
  @override
  List<Object?> get props => [];
}

class PartyMyBookingsStarted extends PartyMyBookingsEvent {
  const PartyMyBookingsStarted();
}

class PartyMyBookingsTabChanged extends PartyMyBookingsEvent {
  const PartyMyBookingsTabChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class PartyMyBookingsCancelPressed extends PartyMyBookingsEvent {
  const PartyMyBookingsCancelPressed(this.bookingId);
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class PartyMyBookingsState extends Equatable {
  const PartyMyBookingsState({
    this.status = PartyStatus.initial,
    this.tabIndex = 0,
    this.bookings = const [],
    this.message,
  });

  final PartyStatus status;
  final int tabIndex;
  final List<PartyBookingEntity> bookings;
  final String? message;

  List<PartyBookingEntity> get visible => bookings
      .where((b) => tabIndex == 0 ? b.isUpcoming : !b.isUpcoming)
      .toList();

  PartyMyBookingsState copyWith({
    PartyStatus? status,
    int? tabIndex,
    List<PartyBookingEntity>? bookings,
    String? message,
  }) =>
      PartyMyBookingsState(
        status: status ?? this.status,
        tabIndex: tabIndex ?? this.tabIndex,
        bookings: bookings ?? this.bookings,
        message: message,
      );

  @override
  List<Object?> get props => [status, tabIndex, bookings, message];
}

class PartyMyBookingsBloc
    extends Bloc<PartyMyBookingsEvent, PartyMyBookingsState> {
  PartyMyBookingsBloc({
    required PartyGetBookingsUseCase getBookings,
    required PartyCancelBookingUseCase cancelBooking,
  })  : _getBookings = getBookings,
        _cancelBooking = cancelBooking,
        super(const PartyMyBookingsState()) {
    on<PartyMyBookingsStarted>(_onStarted);
    on<PartyMyBookingsTabChanged>(
        (e, emit) => emit(state.copyWith(tabIndex: e.index)));
    on<PartyMyBookingsCancelPressed>(_onCancel);
  }

  final PartyGetBookingsUseCase _getBookings;
  final PartyCancelBookingUseCase _cancelBooking;

  Future<void> _onStarted(PartyMyBookingsStarted e,
      Emitter<PartyMyBookingsState> emit) async {
    emit(state.copyWith(status: PartyStatus.loading));
    try {
      final list = await _getBookings(const PartyNoParams());
      emit(state.copyWith(status: PartyStatus.success, bookings: list));
    } catch (_) {
      emit(state.copyWith(status: PartyStatus.failure));
    }
  }

  Future<void> _onCancel(PartyMyBookingsCancelPressed e,
      Emitter<PartyMyBookingsState> emit) async {
    try {
      await _cancelBooking(e.bookingId);
      final list = await _getBookings(const PartyNoParams());
      emit(state.copyWith(
          status: PartyStatus.success,
          bookings: list,
          message: 'Booking cancelled'));
    } catch (_) {
      emit(state.copyWith(message: 'Could not cancel the booking'));
    }
    emit(state.copyWith()); // clears the one-shot message
  }
}
