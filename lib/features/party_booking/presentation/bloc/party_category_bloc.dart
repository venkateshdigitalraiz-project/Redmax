import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecase.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyCategoryEvent extends Equatable {
  const PartyCategoryEvent();
  @override
  List<Object?> get props => [];
}

class PartyCategoryStarted extends PartyCategoryEvent {
  const PartyCategoryStarted();
}

class PartyCategorySearchChanged extends PartyCategoryEvent {
  const PartyCategorySearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class PartyCategoryState extends Equatable {
  const PartyCategoryState({
    this.status = PartyStatus.initial,
    this.categories = const [],
    this.query = '',
    this.results = const [],
    this.searching = false,
  });

  final PartyStatus status;
  final List<PartyCategoryEntity> categories;
  final String query;
  final List<PartyVenueEntity> results;
  final bool searching;

  bool get isSearchMode => query.trim().isNotEmpty;

  PartyCategoryState copyWith({
    PartyStatus? status,
    List<PartyCategoryEntity>? categories,
    String? query,
    List<PartyVenueEntity>? results,
    bool? searching,
  }) =>
      PartyCategoryState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        query: query ?? this.query,
        results: results ?? this.results,
        searching: searching ?? this.searching,
      );

  @override
  List<Object?> get props => [status, categories, query, results, searching];
}

class PartyCategoryBloc extends Bloc<PartyCategoryEvent, PartyCategoryState> {
  PartyCategoryBloc({
    required PartyGetCategoriesUseCase getCategories,
    required PartySearchVenuesUseCase searchVenues,
  })  : _getCategories = getCategories,
        _searchVenues = searchVenues,
        super(const PartyCategoryState()) {
    on<PartyCategoryStarted>(_onStarted);
    on<PartyCategorySearchChanged>(_onSearch);
  }

  final PartyGetCategoriesUseCase _getCategories;
  final PartySearchVenuesUseCase _searchVenues;

  Future<void> _onStarted(
      PartyCategoryStarted e, Emitter<PartyCategoryState> emit) async {
    emit(state.copyWith(status: PartyStatus.loading));
    try {
      final list = await _getCategories(const PartyNoParams());
      emit(state.copyWith(status: PartyStatus.success, categories: list));
    } catch (_) {
      emit(state.copyWith(status: PartyStatus.failure));
    }
  }

  Future<void> _onSearch(
      PartyCategorySearchChanged e, Emitter<PartyCategoryState> emit) async {
    emit(state.copyWith(query: e.query, searching: e.query.trim().isNotEmpty));
    if (e.query.trim().isEmpty) {
      emit(state.copyWith(results: const [], searching: false));
      return;
    }
    try {
      final results =
          await _searchVenues(PartySearchVenuesParams(query: e.query));
      // Ignore stale responses if the query changed meanwhile.
      if (state.query == e.query) {
        emit(state.copyWith(results: results, searching: false));
      }
    } catch (_) {
      emit(state.copyWith(results: const [], searching: false));
    }
  }
}
