import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/carpool_pricing_entity.dart';
import '../../domain/usecases/carpool_calculate_pricing_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolOfferRideEvent extends Equatable {
  const CarpoolOfferRideEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolOfferFromChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferFromChanged(this.value, {this.lat, this.lng});
  final String value;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [value, lat, lng];
}

class CarpoolOfferToChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferToChanged(this.value, {this.lat, this.lng});
  final String value;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [value, lat, lng];
}

class CarpoolOfferSwapPressed extends CarpoolOfferRideEvent {
  const CarpoolOfferSwapPressed();
}

class CarpoolOfferClearRoute extends CarpoolOfferRideEvent {
  const CarpoolOfferClearRoute();
}

class CarpoolOfferCalculatePricing extends CarpoolOfferRideEvent {
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;

  const CarpoolOfferCalculatePricing({
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  List<Object?> get props => [
    originLat,
    originLng,
    destinationLat,
    destinationLng,
  ];
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

class CarpoolOfferPriceChanged extends CarpoolOfferRideEvent {
  const CarpoolOfferPriceChanged(this.delta, {this.currentBasePrice});
  final int delta;
  final int? currentBasePrice;

  @override
  List<Object?> get props => [delta, currentBasePrice];
}

class CarpoolOfferPricePerSeatSet extends CarpoolOfferRideEvent {
  const CarpoolOfferPricePerSeatSet(this.price);
  final int price;

  @override
  List<Object?> get props => [price];
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

class CarpoolOfferVehicleChanged extends CarpoolOfferRideEvent {
  final String model;
  final String number;

  const CarpoolOfferVehicleChanged({
    required this.model,
    required this.number,
  });

  @override
  List<Object?> get props => [model, number];
}

class CarpoolOfferStopoverToggled extends CarpoolOfferRideEvent {
  const CarpoolOfferStopoverToggled(this.stopover);
  final String stopover;

  @override
  List<Object?> get props => [stopover];
}

class CarpoolOfferStopoverAdded extends CarpoolOfferRideEvent {
  const CarpoolOfferStopoverAdded(this.stopover);
  final String stopover;

  @override
  List<Object?> get props => [stopover];
}

class CarpoolOfferStopoverRemoved extends CarpoolOfferRideEvent {
  const CarpoolOfferStopoverRemoved(this.stopover);
  final String stopover;

  @override
  List<Object?> get props => [stopover];
}

class CarpoolOfferStopoversReordered extends CarpoolOfferRideEvent {
  const CarpoolOfferStopoversReordered(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class CarpoolOfferRouteSuggestionsLoaded extends CarpoolOfferRideEvent {
  const CarpoolOfferRouteSuggestionsLoaded(this.suggestedStopovers);
  final List<String> suggestedStopovers;

  @override
  List<Object?> get props => [suggestedStopovers];
}

class CarpoolOfferResetStatus extends CarpoolOfferRideEvent {
  const CarpoolOfferResetStatus();
}

class CarpoolOfferRideState extends Equatable {
  const CarpoolOfferRideState({
    required this.from,
    required this.to,
    required this.departure,
    this.fromLat = 17.3850,
    this.fromLng = 78.4867,
    this.toLat = 16.5062,
    this.toLng = 80.6480,
    this.seats = 3,
    this.pricePerSeat,
    this.rideType = CarpoolRideType.normal,
    this.status = CarpoolStatus.initial,
    this.publishedRide,
    this.error,
    this.stopovers = const [],
    this.selectedStopovers = const {},
    this.pricingCalculation,
    this.isPricingLoading = false,
    this.vehicleModel = '',
    this.vehicleNumber = '',
  });

  factory CarpoolOfferRideState.initial() {
    final n = DateTime.now();
    return CarpoolOfferRideState(
      from: '',
      fromLat: 0.0,
      fromLng: 0.0,
      to: '',
      toLat: 0.0,
      toLng: 0.0,
      departure: DateTime(n.year, n.month, n.day, 9),
      stopovers: const [],
      selectedStopovers: const {},
      pricePerSeat: null,
      vehicleModel: '',
      vehicleNumber: '',
    );
  }

  final String from;
  final String to;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime departure;
  final int seats;
  final int? pricePerSeat;
  final CarpoolRideType rideType;
  final CarpoolStatus status;
  final CarpoolRideEntity? publishedRide;
  final String? error;
  final List<String> stopovers;
  final Set<String> selectedStopovers;
  final CarpoolPricingEntity? pricingCalculation;
  final bool isPricingLoading;
  final String vehicleModel;
  final String vehicleNumber;

  bool get isValid =>
      from.trim().isNotEmpty &&
      to.trim().isNotEmpty &&
      from.trim().toLowerCase() != to.trim().toLowerCase() &&
      seats > 0;

  CarpoolOfferRideState copyWith({
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    DateTime? departure,
    int? seats,
    int? pricePerSeat,
    bool clearPrice = false,
    CarpoolRideType? rideType,
    CarpoolStatus? status,
    CarpoolRideEntity? publishedRide,
    String? error,
    List<String>? stopovers,
    Set<String>? selectedStopovers,
    CarpoolPricingEntity? pricingCalculation,
    bool clearPricing = false,
    bool? isPricingLoading,
    String? vehicleModel,
    String? vehicleNumber,
  }) => CarpoolOfferRideState(
    from: from ?? this.from,
    to: to ?? this.to,
    fromLat: fromLat ?? this.fromLat,
    fromLng: fromLng ?? this.fromLng,
    toLat: toLat ?? this.toLat,
    toLng: toLng ?? this.toLng,
    departure: departure ?? this.departure,
    seats: seats ?? this.seats,
    pricePerSeat: clearPrice ? null : (pricePerSeat ?? this.pricePerSeat),
    rideType: rideType ?? this.rideType,
    status: status ?? this.status,
    publishedRide: publishedRide ?? this.publishedRide,
    error: error,
    stopovers: stopovers ?? this.stopovers,
    selectedStopovers: selectedStopovers ?? this.selectedStopovers,
    pricingCalculation: clearPricing
        ? null
        : (pricingCalculation ?? this.pricingCalculation),
    isPricingLoading: isPricingLoading ?? this.isPricingLoading,
    vehicleModel: vehicleModel ?? this.vehicleModel,
    vehicleNumber: vehicleNumber ?? this.vehicleNumber,
  );

  @override
  List<Object?> get props => [
    from,
    to,
    fromLat,
    fromLng,
    toLat,
    toLng,
    departure,
    seats,
    pricePerSeat,
    rideType,
    status,
    publishedRide,
    error,
    stopovers,
    selectedStopovers,
    pricingCalculation,
    isPricingLoading,
    vehicleModel,
    vehicleNumber,
  ];
}

class CarpoolOfferRideBloc
    extends Bloc<CarpoolOfferRideEvent, CarpoolOfferRideState> {
  CarpoolOfferRideBloc({
    required CarpoolPublishRideUseCase publishRide,
    CarpoolCalculatePricingUseCase? calculatePricing,
  }) : _publishRide = publishRide,
       _calculatePricing =
           calculatePricing ??
           CarpoolCalculatePricingUseCase(
             CarpoolRepositoryImpl(CarpoolMockDataSource()),
           ),
       super(CarpoolOfferRideState.initial()) {
    on<CarpoolOfferFromChanged>(_onFromChanged);
    on<CarpoolOfferToChanged>(_onToChanged);
    on<CarpoolOfferSwapPressed>(_onSwapPressed);
    on<CarpoolOfferClearRoute>(
      (e, emit) => emit(
        state.copyWith(
          from: '',
          to: '',
          fromLat: 0.0,
          fromLng: 0.0,
          toLat: 0.0,
          toLng: 0.0,
          stopovers: const [],
          selectedStopovers: const {},
          clearPrice: true,
          clearPricing: true,
        ),
      ),
    );
    on<CarpoolOfferCalculatePricing>(_onCalculatePricing);
    on<CarpoolOfferResetStatus>(
      (e, emit) =>
          emit(state.copyWith(status: CarpoolStatus.initial, error: null)),
    );
    on<CarpoolOfferDateChanged>((e, emit) {
      final d = state.departure;
      emit(
        state.copyWith(
          departure: DateTime(
            e.date.year,
            e.date.month,
            e.date.day,
            d.hour,
            d.minute,
          ),
        ),
      );
    });
    on<CarpoolOfferTimeChanged>((e, emit) {
      final d = state.departure;
      emit(
        state.copyWith(
          departure: DateTime(d.year, d.month, d.day, e.hour, e.minute),
        ),
      );
    });
    on<CarpoolOfferSeatsChanged>(
      (e, emit) =>
          emit(state.copyWith(seats: (state.seats + e.delta).clamp(1, 6))),
    );
    on<CarpoolOfferPriceChanged>((e, emit) {
      final base = state.pricePerSeat ?? e.currentBasePrice ?? 100;
      final updated = (base + e.delta).clamp(10, 15000);
      emit(state.copyWith(pricePerSeat: updated));
    });
    on<CarpoolOfferPricePerSeatSet>((e, emit) {
      emit(state.copyWith(pricePerSeat: e.price.clamp(10, 15000)));
    });
    on<CarpoolOfferRideTypeChanged>(
      (e, emit) => emit(state.copyWith(rideType: e.type)),
    );
    on<CarpoolOfferVehicleChanged>((e, emit) {
      emit(state.copyWith(
        vehicleModel: e.model,
        vehicleNumber: e.number,
      ));
    });
    on<CarpoolOfferPublishPressed>(_onPublish);
    on<CarpoolOfferStopoverToggled>((e, emit) {
      final updated = Set<String>.from(state.selectedStopovers);
      if (updated.contains(e.stopover)) {
        updated.remove(e.stopover);
      } else {
        updated.add(e.stopover);
      }
      emit(state.copyWith(selectedStopovers: updated));
    });
    on<CarpoolOfferStopoverAdded>((e, emit) {
      final trimmed = e.stopover.trim();
      if (trimmed.isEmpty) return;
      final updatedList = List<String>.from(state.stopovers);
      if (!updatedList.contains(trimmed)) {
        updatedList.add(trimmed);
      }
      final orderedList = CarpoolDistanceCalculator.orderStopoversInCorridor(
        start: state.from,
        destination: state.to,
        stopovers: updatedList,
        startLat: state.fromLat,
        startLng: state.fromLng,
        destLat: state.toLat,
        destLng: state.toLng,
      );
      final updatedSelected = Set<String>.from(state.selectedStopovers)
        ..add(trimmed);
      emit(
        state.copyWith(
          stopovers: orderedList,
          selectedStopovers: updatedSelected,
        ),
      );
    });
    on<CarpoolOfferStopoverRemoved>((e, emit) {
      final updatedList = List<String>.from(state.stopovers)
        ..remove(e.stopover);
      final updatedSelected = Set<String>.from(state.selectedStopovers)
        ..remove(e.stopover);
      emit(
        state.copyWith(
          stopovers: updatedList,
          selectedStopovers: updatedSelected,
        ),
      );
    });
    on<CarpoolOfferStopoversReordered>((e, emit) {
      final updatedList = List<String>.from(state.stopovers);
      var newIdx = e.newIndex;
      if (e.oldIndex < newIdx) {
        newIdx -= 1;
      }
      if (e.oldIndex < 0 ||
          e.oldIndex >= updatedList.length ||
          newIdx < 0 ||
          newIdx >= updatedList.length) {
        return;
      }
      final item = updatedList.removeAt(e.oldIndex);
      updatedList.insert(newIdx, item);
      emit(state.copyWith(stopovers: updatedList));
    });
    on<CarpoolOfferRouteSuggestionsLoaded>((e, emit) {
      final validSelected = state.selectedStopovers
          .where((s) => e.suggestedStopovers.contains(s))
          .toSet();

      emit(
        state.copyWith(
          stopovers: e.suggestedStopovers,
          selectedStopovers: validSelected,
        ),
      );
    });
  }

  final CarpoolPublishRideUseCase _publishRide;
  final CarpoolCalculatePricingUseCase _calculatePricing;

  Future<void> _onCalculatePricing(
    CarpoolOfferCalculatePricing event,
    Emitter<CarpoolOfferRideState> emit,
  ) async {
    emit(state.copyWith(isPricingLoading: true));

    final fromGeo = CarpoolDistanceCalculator.findGeo(state.from);
    final toGeo = CarpoolDistanceCalculator.findGeo(state.to);

    final oLat =
        event.originLat ??
        (state.fromLat != 0.0 ? state.fromLat : null) ??
        fromGeo?.lat ??
        28.6139;
    final oLng =
        event.originLng ??
        (state.fromLng != 0.0 ? state.fromLng : null) ??
        fromGeo?.lng ??
        77.2090;
    final dLat =
        event.destinationLat ??
        (state.toLat != 0.0 ? state.toLat : null) ??
        toGeo?.lat ??
        26.9124;
    final dLng =
        event.destinationLng ??
        (state.toLng != 0.0 ? state.toLng : null) ??
        toGeo?.lng ??
        75.7873;

    try {
      final result = await _calculatePricing(
        CarpoolCalculatePricingParams(
          originLat: oLat,
          originLng: oLng,
          destinationLat: dLat,
          destinationLng: dLng,
        ),
      );

      emit(
        state.copyWith(
          pricingCalculation: result,
          isPricingLoading: false,
          fromLat: oLat,
          fromLng: oLng,
          toLat: dLat,
          toLng: dLng,
          pricePerSeat: result.suggestedPrice,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isPricingLoading: false, error: e.toString()));
    }
  }

  void _onFromChanged(
    CarpoolOfferFromChanged event,
    Emitter<CarpoolOfferRideState> emit,
  ) {
    final geo = (event.lat != null && event.lng != null)
        ? null
        : CarpoolDistanceCalculator.findGeo(event.value);
    final lat = event.lat ?? geo?.lat ?? state.fromLat;
    final lng = event.lng ?? geo?.lng ?? state.fromLng;

    emit(
      state.copyWith(
        from: event.value,
        fromLat: lat,
        fromLng: lng,
        stopovers: const [],
        selectedStopovers: const {},
        status: CarpoolStatus.initial,
        error: null,
      ),
    );
  }

  void _onToChanged(
    CarpoolOfferToChanged event,
    Emitter<CarpoolOfferRideState> emit,
  ) {
    final geo = (event.lat != null && event.lng != null)
        ? null
        : CarpoolDistanceCalculator.findGeo(event.value);
    final lat = event.lat ?? geo?.lat ?? state.toLat;
    final lng = event.lng ?? geo?.lng ?? state.toLng;

    emit(
      state.copyWith(
        to: event.value,
        toLat: lat,
        toLng: lng,
        stopovers: const [],
        selectedStopovers: const {},
        status: CarpoolStatus.initial,
        error: null,
      ),
    );
  }

  void _onSwapPressed(
    CarpoolOfferSwapPressed event,
    Emitter<CarpoolOfferRideState> emit,
  ) {
    emit(
      state.copyWith(
        from: state.to,
        to: state.from,
        fromLat: state.toLat,
        fromLng: state.toLng,
        toLat: state.fromLat,
        toLng: state.fromLng,
        stopovers: const [],
        selectedStopovers: const {},
        status: CarpoolStatus.initial,
        error: null,
      ),
    );
  }

  Future<void> _onPublish(
    CarpoolOfferPublishPressed event,
    Emitter<CarpoolOfferRideState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final fromGeo = CarpoolDistanceCalculator.findGeo(state.from);
      final toGeo = CarpoolDistanceCalculator.findGeo(state.to);

      final oLat = state.fromLat != 0.0
          ? state.fromLat
          : (fromGeo?.lat ?? 28.6315);
      final oLng = state.fromLng != 0.0
          ? state.fromLng
          : (fromGeo?.lng ?? 77.2167);
      final dLat = state.toLat != 0.0
          ? state.toLat
          : (toGeo?.lat ?? 26.9220);
      final dLng = state.toLng != 0.0
          ? state.toLng
          : (toGeo?.lng ?? 75.7789);

      final vehicleStr = [
        if (state.vehicleModel.trim().isNotEmpty) state.vehicleModel.trim(),
        if (state.vehicleNumber.trim().isNotEmpty) state.vehicleNumber.trim(),
      ].join(' • ');

      final ride = await _publishRide(
        CarpoolPublishRideParams(
          from: state.from,
          to: state.to,
          departure: state.departure,
          seats: state.seats,
          rideType: state.rideType,
          pricePerSeat: state.pricePerSeat ??
              (state.pricingCalculation?.suggestedPrice ?? 750),
          vehicle: vehicleStr.isNotEmpty ? vehicleStr : 'Honda City',
          origin: state.from,
          originLat: oLat,
          originLng: oLng,
          originCity: fromGeo?.district ??
              (state.from.contains(',')
                  ? state.from.split(',').last.trim()
                  : state.from),
          destination: state.to,
          destinationLat: dLat,
          destinationLng: dLng,
          destinationCity: toGeo?.district ??
              (state.to.contains(',')
                  ? state.to.split(',').last.trim()
                  : state.to),
          departureTime: CarpoolFormatters.toUtcIso(state.departure),
          availableSeats: state.seats,
          vehicleModel: state.vehicleModel.isNotEmpty
              ? state.vehicleModel
              : 'Honda City',
          vehicleNumber: state.vehicleNumber.isNotEmpty
              ? state.vehicleNumber
              : 'DL 01 AB 1234',
          notes: 'Direct highway drive, air-conditioned.',
        ),
      );
      emit(state.copyWith(status: CarpoolStatus.success, publishedRide: ride));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, error: '$e'));
    }
  }
}
