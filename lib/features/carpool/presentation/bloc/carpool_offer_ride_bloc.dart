import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolOfferRideEvent extends Equatable {
  const CarpoolOfferRideEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolOfferFromChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferFromChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class CarpoolOfferToChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferToChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class CarpoolOfferSwapPressed extends CarpoolOfferRideEvent {
  const CarpoolOfferSwapPressed();
}

class CarpoolOfferDateChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class CarpoolOfferTimeChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferTimeChanged(this.hour, this.minute);
  final int hour;
  final int minute;
  @override
  List<Object?> get props => [hour, minute];
}

class CarpoolOfferSeatsChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferSeatsChanged(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

class CarpoolOfferRideTypeChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferRideTypeChanged(this.type);
  final CarpoolRideType type;
  @override
  List<Object?> get props => [type];
}

class CarpoolOfferPublishPressed extends CarpoolOfferRideEvent {
  const CarpoolOfferPublishPressed();
}

class CarpoolOfferRideState extends Equatable {
  const CarpoolOfferRideState({
    required this.from,
    required this.to,
    required this.departure,
    this.seats = 3,
    this.rideType = CarpoolRideType.normal,
    this.status = CarpoolStatus.initial,
    this.publishedRide,
    this.error,
  });

  factory CarpoolOfferRideState.initial() {
    final n = DateTime.now();
    return CarpoolOfferRideState(
      from: 'Hyderabad',
      to: 'Vijayawada',
      departure: DateTime(n.year, n.month, n.day, 9),
    );
  }

  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final CarpoolRideType rideType;
  final CarpoolStatus status;
  final CarpoolRideEntity? publishedRide;
  final String? error;

  bool get isValid =>
      from.trim().isNotEmpty &&
      to.trim().isNotEmpty &&
      from.trim().toLowerCase() != to.trim().toLowerCase() &&
      seats > 0;

  CarpoolOfferRideState copyWith({
    String? from,
    String? to,
    DateTime? departure,
    int? seats,
    CarpoolRideType? rideType,
    CarpoolStatus? status,
    CarpoolRideEntity? publishedRide,
    String? error,
  }) =>
      CarpoolOfferRideState(
        from: from ?? this.from,
        to: to ?? this.to,
        departure: departure ?? this.departure,
        seats: seats ?? this.seats,
        rideType: rideType ?? this.rideType,
        status: status ?? this.status,
        publishedRide: publishedRide ?? this.publishedRide,
        error: error,
      );

  @override
  List<Object?> get props =>
      [from, to, departure, seats, rideType, status, publishedRide, error];
}

class CarpoolOfferRideBloc
    extends Bloc<CarpoolOfferRideEvent, CarpoolOfferRideState> {
  CarpoolOfferRideBloc({required CarpoolPublishRideUseCase publishRide})
      : _publishRide = publishRide,
        super(CarpoolOfferRideState.initial()) {
    on<CarpoolOfferFromChanged>((e, emit) => emit(state.copyWith(from: e.value)));
    on<CarpoolOfferToChanged>((e, emit) => emit(state.copyWith(to: e.value)));
    on<CarpoolOfferSwapPressed>(
        (e, emit) => emit(state.copyWith(from: state.to, to: state.from)));
    on<CarpoolOfferDateChanged>((e, emit) {
      final d = state.departure;
      emit(state.copyWith(
          departure: DateTime(e.date.year, e.date.month, e.date.day, d.hour,
              d.minute)));
    });
    on<CarpoolOfferTimeChanged>((e, emit) {
      final d = state.departure;
      emit(state.copyWith(
          departure: DateTime(d.year, d.month, d.day, e.hour, e.minute)));
    });
    on<CarpoolOfferSeatsChanged>((e, emit) =>
        emit(state.copyWith(seats: (state.seats + e.delta).clamp(1, 6))));
    on<CarpoolOfferRideTypeChanged>(
        (e, emit) => emit(state.copyWith(rideType: e.type)));
    on<CarpoolOfferPublishPressed>(_onPublish);
  }

  final CarpoolPublishRideUseCase _publishRide;

  Future<void> _onPublish(CarpoolOfferPublishPressed event,
      Emitter<CarpoolOfferRideState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final ride = await _publishRide(CarpoolPublishRideParams(
        from: state.from,
        to: state.to,
        departure: state.departure,
        seats: state.seats,
        rideType: state.rideType,
      ));
      emit(state.copyWith(status: CarpoolStatus.success, publishedRide: ride));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, error: '$e'));
    }
  }
}
