import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/usecases/get_place_predictions_usecase.dart';

enum PlacesAutocompleteStatus { initial, loading, loaded, error }

abstract class PlacesAutocompleteEvent extends Equatable {
  const PlacesAutocompleteEvent();

  @override
  List<Object?> get props => [];
}

class PlaceQueryChanged extends PlacesAutocompleteEvent {
  final String query;

  const PlaceQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PlaceQueryCleared extends PlacesAutocompleteEvent {
  const PlaceQueryCleared();
}

class PlaceQueryInitialRequested extends PlacesAutocompleteEvent {
  const PlaceQueryInitialRequested();
}

class PlacesAutocompleteState extends Equatable {
  final PlacesAutocompleteStatus status;
  final List<PlacePredictionEntity> predictions;
  final String query;
  final String? errorMessage;

  const PlacesAutocompleteState({
    this.status = PlacesAutocompleteStatus.initial,
    this.predictions = const [],
    this.query = '',
    this.errorMessage,
  });

  PlacesAutocompleteState copyWith({
    PlacesAutocompleteStatus? status,
    List<PlacePredictionEntity>? predictions,
    String? query,
    String? errorMessage,
  }) {
    return PlacesAutocompleteState(
      status: status ?? this.status,
      predictions: predictions ?? this.predictions,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, predictions, query, errorMessage];
}

class PlacesAutocompleteBloc
    extends Bloc<PlacesAutocompleteEvent, PlacesAutocompleteState> {
  final GetPlacePredictionsUseCase getPlacePredictions;
  Timer? _debounceTimer;

  PlacesAutocompleteBloc({required this.getPlacePredictions})
      : super(const PlacesAutocompleteState()) {
    on<PlaceQueryChanged>(_onQueryChanged);
    on<PlaceQueryCleared>(_onQueryCleared);
    on<PlaceQueryInitialRequested>(_onInitialRequested);
  }

  Future<void> _onInitialRequested(
    PlaceQueryInitialRequested event,
    Emitter<PlacesAutocompleteState> emit,
  ) async {
    emit(state.copyWith(status: PlacesAutocompleteStatus.loading));
    try {
      final predictions = await getPlacePredictions('');
      emit(
        state.copyWith(
          status: PlacesAutocompleteStatus.loaded,
          predictions: predictions,
          query: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlacesAutocompleteStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onQueryChanged(
    PlaceQueryChanged event,
    Emitter<PlacesAutocompleteState> emit,
  ) async {
    final query = event.query;
    emit(state.copyWith(query: query, status: PlacesAutocompleteStatus.loading));

    try {
      final predictions = await getPlacePredictions(query);
      emit(
        state.copyWith(
          status: PlacesAutocompleteStatus.loaded,
          predictions: predictions,
          query: query,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlacesAutocompleteStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onQueryCleared(
    PlaceQueryCleared event,
    Emitter<PlacesAutocompleteState> emit,
  ) {
    add(const PlaceQueryInitialRequested());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

