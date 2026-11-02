import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolMyRidesEvent extends Equatable {
  const CarpoolMyRidesEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolMyRidesStarted extends CarpoolMyRidesEvent {
  const CarpoolMyRidesStarted();
}

class CarpoolMyRidesTabChanged extends CarpoolMyRidesEvent {
  const CarpoolMyRidesTabChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class CarpoolMyRidesCancelPressed extends CarpoolMyRidesEvent {
  const CarpoolMyRidesCancelPressed(this.rideId);
  final String rideId;
  @override
  List<Object?> get props => [rideId];
}

class CarpoolMyRidesState extends Equatable {
  const CarpoolMyRidesState({
    this.status = CarpoolStatus.initial,
    this.tabIndex = 0,
    this.rides = const [],
    this.message,
  });

  final CarpoolStatus status;
  final int tabIndex;
  final List<CarpoolRideEntity> rides;
  final String? message;

  List<CarpoolRideEntity> get visibleRides => rides
      .where(
        (r) => tabIndex == 0
            ? r.status == CarpoolRideStatus.upcoming
            : r.status != CarpoolRideStatus.upcoming,
      )
      .toList();

  CarpoolMyRidesState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    List<CarpoolRideEntity>? rides,
    String? message,
  }) => CarpoolMyRidesState(
    status: status ?? this.status,
    tabIndex: tabIndex ?? this.tabIndex,
    rides: rides ?? this.rides,
    message: message,
  );

  @override
  List<Object?> get props => [status, tabIndex, rides, message];
}

class CarpoolMyRidesBloc
    extends Bloc<CarpoolMyRidesEvent, CarpoolMyRidesState> {
  CarpoolMyRidesBloc({
    required CarpoolGetMyRidesUseCase getMyRides,
    required CarpoolCancelRideUseCase cancelRide,
  }) : _getMyRides = getMyRides,
       _cancelRide = cancelRide,
       super(const CarpoolMyRidesState()) {
    on<CarpoolMyRidesStarted>(_onStarted);
    on<CarpoolMyRidesTabChanged>(
      (e, emit) => emit(state.copyWith(tabIndex: e.index)),
    );
    on<CarpoolMyRidesCancelPressed>(_onCancel);
  }

  final CarpoolGetMyRidesUseCase _getMyRides;
  final CarpoolCancelRideUseCase _cancelRide;

  Future<void> _onStarted(
    CarpoolMyRidesStarted e,
    Emitter<CarpoolMyRidesState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final rides = await _getMyRides(const CarpoolNoParams());
      emit(state.copyWith(status: CarpoolStatus.success, rides: rides));
    } catch (err) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: '$err'));
    }
  }

  Future<void> _onCancel(
    CarpoolMyRidesCancelPressed e,
    Emitter<CarpoolMyRidesState> emit,
  ) async {
    try {
      await _cancelRide(e.rideId);
      final rides = await _getMyRides(const CarpoolNoParams());
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          rides: rides,
          message: 'Ride cancelled',
        ),
      );
    } catch (err) {
      emit(state.copyWith(message: 'Could not cancel the ride'));
    }
    emit(state.copyWith());
  }
}
