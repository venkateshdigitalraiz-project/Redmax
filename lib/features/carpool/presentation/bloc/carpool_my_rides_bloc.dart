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
    this.cancellingRideId,
  });

  final CarpoolStatus status;
  final int tabIndex;
  final List<CarpoolRideEntity> rides;
  final String? message;
  final String? cancellingRideId;

  List<CarpoolRideEntity> get visibleRides => rides
      .where(
        (r) => tabIndex == 0
            ? r.status == CarpoolRideStatus.upcoming
            : r.status != CarpoolRideStatus.upcoming,
      )
      .toList();

  int get upcomingCount =>
      rides.where((r) => r.status == CarpoolRideStatus.upcoming).length;
  int get pastCount =>
      rides.where((r) => r.status != CarpoolRideStatus.upcoming).length;

  int get totalBookingsCount {
    int total = 0;
    for (final r in rides) {
      total += r.totalBookings;
    }
    return total;
  }

  CarpoolMyRidesState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    List<CarpoolRideEntity>? rides,
    String? message,
    String? cancellingRideId,
    bool clearCancelling = false,
  }) => CarpoolMyRidesState(
    status: status ?? this.status,
    tabIndex: tabIndex ?? this.tabIndex,
    rides: rides ?? this.rides,
    message: message,
    cancellingRideId: clearCancelling
        ? null
        : (cancellingRideId ?? this.cancellingRideId),
  );

  @override
  List<Object?> get props => [
    status,
    tabIndex,
    rides,
    message,
    cancellingRideId,
  ];
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
    // 1. Mark only this specific ride as cancelling
    emit(state.copyWith(cancellingRideId: e.rideId));
    try {
      await _cancelRide(e.rideId);
      // 2. Update only this specific ride in the list without affecting others
      final updatedRides = state.rides.map((r) {
        if (r.id == e.rideId) {
          return r.copyWith(status: CarpoolRideStatus.cancelled);
        }
        return r;
      }).toList();

      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          rides: updatedRides,
          clearCancelling: true,
          message: 'Booking cancelled successfully',
        ),
      );
    } catch (err) {
      final msg = err.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          clearCancelling: true,
          message: msg.isNotEmpty ? msg : 'Could not cancel the ride',
        ),
      );
    }
  }
}
