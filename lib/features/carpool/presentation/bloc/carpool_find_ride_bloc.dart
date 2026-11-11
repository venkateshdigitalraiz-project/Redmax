import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolFindRideEvent extends Equatable {
  const CarpoolFindRideEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolFindRideRouteSelected extends CarpoolFindRideEvent {
  const CarpoolFindRideRouteSelected(
    this.from,
    this.to, {
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  final String from;
  final String to;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  @override
  List<Object?> get props => [from, to, fromLat, fromLng, toLat, toLng];
}

class CarpoolFindRideFilterChanged extends CarpoolFindRideEvent {
  const CarpoolFindRideFilterChanged(this.filter);
  final CarpoolDayFilter filter;
  @override
  List<Object?> get props => [filter];
}

class CarpoolFindRideFavoriteToggled extends CarpoolFindRideEvent {
  const CarpoolFindRideFavoriteToggled(this.rideId);
  final String rideId;
  @override
  List<Object?> get props => [rideId];
}

class CarpoolFindRideBookPressed extends CarpoolFindRideEvent {
  const CarpoolFindRideBookPressed(this.ride);
  final CarpoolRideEntity ride;
  @override
  List<Object?> get props => [ride];
}

class CarpoolFindRideState extends Equatable {
  const CarpoolFindRideState({
    this.status = CarpoolStatus.initial,
    this.from = 'Current Location',
    this.fromLat = 17.3850,
    this.fromLng = 78.4867,
    this.to = '',
    this.toLat = 0.0,
    this.toLng = 0.0,
    this.filter = CarpoolDayFilter.today,
    this.rides = const [],
    this.favorites = const {},
    this.bookingId,
    this.message,
  });

  final CarpoolStatus status;
  final String from;
  final double fromLat;
  final double fromLng;
  final String to;
  final double toLat;
  final double toLng;
  final CarpoolDayFilter filter;
  final List<CarpoolRideEntity> rides;
  final Set<String> favorites;
  final String? bookingId;
  final String? message;

  int get distanceKm => rides.isNotEmpty
      ? rides.first.distanceKm
      : CarpoolDistanceCalculator.calculateDistanceKm(
          from,
          to,
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );

  CarpoolFindRideState copyWith({
    CarpoolStatus? status,
    String? from,
    double? fromLat,
    double? fromLng,
    String? to,
    double? toLat,
    double? toLng,
    CarpoolDayFilter? filter,
    List<CarpoolRideEntity>? rides,
    Set<String>? favorites,
    String? bookingId,
    String? message,
    bool clearBooking = false,
  }) => CarpoolFindRideState(
    status: status ?? this.status,
    from: from ?? this.from,
    fromLat: fromLat ?? this.fromLat,
    fromLng: fromLng ?? this.fromLng,
    to: to ?? this.to,
    toLat: toLat ?? this.toLat,
    toLng: toLng ?? this.toLng,
    filter: filter ?? this.filter,
    rides: rides ?? this.rides,
    favorites: favorites ?? this.favorites,
    bookingId: clearBooking ? null : (bookingId ?? this.bookingId),
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    from,
    fromLat,
    fromLng,
    to,
    toLat,
    toLng,
    filter,
    rides,
    favorites,
    bookingId,
    message,
  ];
}

class CarpoolFindRideBloc
    extends Bloc<CarpoolFindRideEvent, CarpoolFindRideState> {
  CarpoolFindRideBloc({
    required CarpoolSearchRidesUseCase searchRides,
    required CarpoolBookRideUseCase bookRide,
  }) : _searchRides = searchRides,
       _bookRide = bookRide,
       super(const CarpoolFindRideState()) {
    on<CarpoolFindRideRouteSelected>((e, emit) async {
      final geoFrom = (e.fromLat != null && e.fromLng != null)
          ? null
          : CarpoolDistanceCalculator.findGeo(e.from);
      final geoTo = (e.toLat != null && e.toLng != null)
          ? null
          : CarpoolDistanceCalculator.findGeo(e.to);

      final fLat = e.fromLat ?? geoFrom?.lat ?? state.fromLat;
      final fLng = e.fromLng ?? geoFrom?.lng ?? state.fromLng;
      final tLat = e.toLat ?? geoTo?.lat ?? state.toLat;
      final tLng = e.toLng ?? geoTo?.lng ?? state.toLng;

      emit(state.copyWith(
        from: e.from,
        fromLat: fLat,
        fromLng: fLng,
        to: e.to,
        toLat: tLat,
        toLng: tLng,
      ));
      await _search(emit);
    });
    on<CarpoolFindRideFilterChanged>((e, emit) async {
      emit(state.copyWith(filter: e.filter));
      await _search(emit);
    });
    on<CarpoolFindRideFavoriteToggled>((e, emit) {
      final favs = {...state.favorites};
      favs.contains(e.rideId) ? favs.remove(e.rideId) : favs.add(e.rideId);
      emit(state.copyWith(favorites: favs));
    });
    on<CarpoolFindRideBookPressed>(_onBook);
  }

  final CarpoolSearchRidesUseCase _searchRides;
  final CarpoolBookRideUseCase _bookRide;

  Future<void> _search(Emitter<CarpoolFindRideState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final rides = await _searchRides(
        CarpoolSearchRidesParams(
          from: state.from,
          to: state.to,
          filter: state.filter,
        ),
      );
      emit(state.copyWith(status: CarpoolStatus.success, rides: rides));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: '$e'));
    }
  }

  Future<void> _onBook(
    CarpoolFindRideBookPressed e,
    Emitter<CarpoolFindRideState> emit,
  ) async {
    emit(state.copyWith(bookingId: e.ride.id));
    try {
      await _bookRide(e.ride.id);
      emit(
        state.copyWith(
          clearBooking: true,
          message: 'Ride booked with ${e.ride.driverName}',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          clearBooking: true,
          message: 'Could not book this ride. Try again.',
        ),
      );
    }
    emit(state.copyWith()); // clears the one-shot message
  }
}
