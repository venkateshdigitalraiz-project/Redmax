import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyBookingFormEvent extends Equatable {
  const PartyBookingFormEvent();
  @override
  List<Object?> get props => [];
}

class PartyBookingFormStarted extends PartyBookingFormEvent {
  const PartyBookingFormStarted();
}

class PartyBookingDateChanged extends PartyBookingFormEvent {
  const PartyBookingDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class PartyBookingSlotSelected extends PartyBookingFormEvent {
  const PartyBookingSlotSelected(this.slot);
  final String slot;
  @override
  List<Object?> get props => [slot];
}

class PartyBookingGuestsChanged extends PartyBookingFormEvent {
  const PartyBookingGuestsChanged(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

class PartyBookingNameChanged extends PartyBookingFormEvent {
  const PartyBookingNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PartyBookingPhoneChanged extends PartyBookingFormEvent {
  const PartyBookingPhoneChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PartyBookingNotesChanged extends PartyBookingFormEvent {
  const PartyBookingNotesChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PartyBookingPaymentSelected extends PartyBookingFormEvent {
  const PartyBookingPaymentSelected(this.method);
  final PartyPaymentMethod method;
  @override
  List<Object?> get props => [method];
}

class PartyBookingNextPressed extends PartyBookingFormEvent {
  const PartyBookingNextPressed();
}

class PartyBookingBackPressed extends PartyBookingFormEvent {
  const PartyBookingBackPressed();
}

class PartyBookingFormState extends Equatable {
  const PartyBookingFormState({
    required this.venue,
    required this.date,
    required this.guests,
    this.step = 0,
    this.slots = const [],
    this.slot = '1:00 PM',
    this.name = '',
    this.phone = '',
    this.notes = '',
    this.payment,
    this.status = PartyStatus.initial,
    this.booking,
    this.error,
  });

  final PartyVenueEntity venue;
  final int step; // 0 Date & Time, 1 Details, 2 Payment, 3 Confirm
  final DateTime date;
  final List<String> slots;
  final String? slot;
  final int guests;
  final String name;
  final String phone;
  final String notes;
  final PartyPaymentMethod? payment;
  final PartyStatus status;
  final PartyBookingEntity? booking;
  final String? error;

  int get totalAmount => venue.priceFrom;
  int get advanceAmount => (venue.priceFrom * .2).round();
  bool get isLastStep => step == 3;

  PartyBookingFormState copyWith({
    int? step,
    DateTime? date,
    List<String>? slots,
    String? slot,
    int? guests,
    String? name,
    String? phone,
    String? notes,
    PartyPaymentMethod? payment,
    PartyStatus? status,
    PartyBookingEntity? booking,
    String? error,
  }) =>
      PartyBookingFormState(
        venue: venue,
        step: step ?? this.step,
        date: date ?? this.date,
        slots: slots ?? this.slots,
        slot: slot ?? this.slot,
        guests: guests ?? this.guests,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        payment: payment ?? this.payment,
        status: status ?? this.status,
        booking: booking ?? this.booking,
        error: error,
      );

  @override
  List<Object?> get props => [
        venue, step, date, slots, slot, guests, name, phone, notes, payment,
        status, booking, error,
      ];
}

class PartyBookingFormBloc
    extends Bloc<PartyBookingFormEvent, PartyBookingFormState> {
  PartyBookingFormBloc({
    required PartyVenueEntity venue,
    required PartyGetTimeSlotsUseCase getTimeSlots,
    required PartyCreateBookingUseCase createBooking,
  })  : _getTimeSlots = getTimeSlots,
        _createBooking = createBooking,
        super(PartyBookingFormState(
          venue: venue,
          date: _defaultDate(),
          guests: math.min(100, venue.capacity),
        )) {
    on<PartyBookingFormStarted>((e, emit) => _loadSlots(emit));
    on<PartyBookingDateChanged>((e, emit) async {
      emit(state.copyWith(date: e.date));
      await _loadSlots(emit);
    });
    on<PartyBookingSlotSelected>(
        (e, emit) => emit(state.copyWith(slot: e.slot)));
    on<PartyBookingGuestsChanged>((e, emit) {
      final next =
          (state.guests + e.delta).clamp(10, math.max(10, state.venue.capacity)).toInt();
      emit(state.copyWith(guests: next));
    });
    on<PartyBookingNameChanged>((e, emit) => emit(state.copyWith(name: e.value)));
    on<PartyBookingPhoneChanged>(
        (e, emit) => emit(state.copyWith(phone: e.value)));
    on<PartyBookingNotesChanged>(
        (e, emit) => emit(state.copyWith(notes: e.value)));
    on<PartyBookingPaymentSelected>(
        (e, emit) => emit(state.copyWith(payment: e.method)));
    on<PartyBookingBackPressed>((e, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1));
    });
    on<PartyBookingNextPressed>(_onNext);
  }

  final PartyGetTimeSlotsUseCase _getTimeSlots;
  final PartyCreateBookingUseCase _createBooking;

  static DateTime _defaultDate() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + 7);
  }

  Future<void> _loadSlots(Emitter<PartyBookingFormState> emit) async {
    try {
      final slots = await _getTimeSlots(
          PartyTimeSlotsParams(venueId: state.venue.id, date: state.date));
      final keep = slots.contains(state.slot)
          ? state.slot
          : (slots.contains('1:00 PM') ? '1:00 PM' : slots.first);
      emit(state.copyWith(slots: slots, slot: keep));
    } catch (e) {
      emit(state.copyWith(error: 'Could not load time slots.'));
      emit(state.copyWith());
    }
  }

  String? _validate() {
    switch (state.step) {
      case 0:
        if (state.slot == null) return 'Pick a time slot.';
        if (state.guests > state.venue.capacity) {
          return 'This venue hosts up to ${state.venue.capacity} guests.';
        }
        return null;
      case 1:
        if (state.name.trim().length < 2) return 'Enter your full name.';
        if (state.phone.replaceAll(RegExp(r'\D'), '').length != 10) {
          return 'Enter a valid 10-digit phone number.';
        }
        return null;
      case 2:
        if (state.payment == null) return 'Choose a payment method.';
        return null;
    }
    return null;
  }

  Future<void> _onNext(PartyBookingNextPressed e,
      Emitter<PartyBookingFormState> emit) async {
    if (state.status == PartyStatus.loading) return;
    final problem = _validate();
    if (problem != null) {
      emit(state.copyWith(error: problem));
      emit(state.copyWith()); // clears the one-shot error
      return;
    }
    if (!state.isLastStep) {
      emit(state.copyWith(step: state.step + 1));
      return;
    }
    emit(state.copyWith(status: PartyStatus.loading));
    try {
      final booking = await _createBooking(PartyCreateBookingParams(
        venueId: state.venue.id,
        date: state.date,
        timeSlot: state.slot!,
        guests: state.guests,
        guestName: state.name,
        phone: state.phone,
        notes: state.notes,
        paymentMethod: state.payment!,
      ));
      emit(state.copyWith(status: PartyStatus.success, booking: booking));
    } catch (err) {
      emit(state.copyWith(status: PartyStatus.failure, error: '$err'));
      emit(state.copyWith(status: PartyStatus.initial));
    }
  }
}
