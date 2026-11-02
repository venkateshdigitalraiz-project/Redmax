import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyVenueListEvent extends Equatable {
  const PartyVenueListEvent();
  @override
  List<Object?> get props => [];
}

class PartyVenueListStarted extends PartyVenueListEvent {
  const PartyVenueListStarted(this.categoryId);
  final String? categoryId;
  @override
  List<Object?> get props => [categoryId];
}

class PartyVenueListState extends Equatable {
  const PartyVenueListState({
    this.status = PartyStatus.initial,
    this.venues = const [],
  });

  final PartyStatus status;
  final List<PartyVenueEntity> venues;

  @override
  List<Object?> get props => [status, venues];
}

class PartyVenueListBloc
    extends Bloc<PartyVenueListEvent, PartyVenueListState> {
  PartyVenueListBloc({required PartySearchVenuesUseCase searchVenues})
      : _searchVenues = searchVenues,
        super(const PartyVenueListState()) {
    on<PartyVenueListStarted>(_onStarted);
  }

  final PartySearchVenuesUseCase _searchVenues;

  Future<void> _onStarted(
      PartyVenueListStarted e, Emitter<PartyVenueListState> emit) async {
    emit(const PartyVenueListState(status: PartyStatus.loading));
    try {
      final venues =
          await _searchVenues(PartySearchVenuesParams(categoryId: e.categoryId));
      emit(PartyVenueListState(status: PartyStatus.success, venues: venues));
    } catch (_) {
      emit(const PartyVenueListState(status: PartyStatus.failure));
    }
  }
}
