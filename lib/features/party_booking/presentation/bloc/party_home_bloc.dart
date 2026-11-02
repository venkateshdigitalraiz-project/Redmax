import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecase.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyHomeEvent extends Equatable {
  const PartyHomeEvent();
  @override
  List<Object?> get props => [];
}

class PartyHomeStarted extends PartyHomeEvent {
  const PartyHomeStarted();
}

class PartyHomeState extends Equatable {
  const PartyHomeState({
    this.status = PartyStatus.initial,
    this.categories = const [],
    this.popularVenues = const [],
    this.error,
  });

  final PartyStatus status;
  final List<PartyCategoryEntity> categories;
  final List<PartyVenueEntity> popularVenues;
  final String? error;

  PartyHomeState copyWith({
    PartyStatus? status,
    List<PartyCategoryEntity>? categories,
    List<PartyVenueEntity>? popularVenues,
    String? error,
  }) =>
      PartyHomeState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        popularVenues: popularVenues ?? this.popularVenues,
        error: error,
      );

  @override
  List<Object?> get props => [status, categories, popularVenues, error];
}

class PartyHomeBloc extends Bloc<PartyHomeEvent, PartyHomeState> {
  PartyHomeBloc({
    required PartyGetCategoriesUseCase getCategories,
    required PartyGetPopularVenuesUseCase getPopularVenues,
  })  : _getCategories = getCategories,
        _getPopularVenues = getPopularVenues,
        super(const PartyHomeState()) {
    on<PartyHomeStarted>(_onStarted);
  }

  final PartyGetCategoriesUseCase _getCategories;
  final PartyGetPopularVenuesUseCase _getPopularVenues;

  Future<void> _onStarted(
      PartyHomeStarted e, Emitter<PartyHomeState> emit) async {
    emit(state.copyWith(status: PartyStatus.loading));
    try {
      final categories = await _getCategories(const PartyNoParams());
      final venues = await _getPopularVenues(const PartyNoParams());
      emit(state.copyWith(
          status: PartyStatus.success,
          categories: categories,
          popularVenues: venues));
    } catch (err) {
      emit(state.copyWith(status: PartyStatus.failure, error: '$err'));
    }
  }
}
