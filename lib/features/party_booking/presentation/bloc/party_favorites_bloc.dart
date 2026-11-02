import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecase.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyFavoritesEvent extends Equatable {
  const PartyFavoritesEvent();
  @override
  List<Object?> get props => [];
}

class PartyFavoritesStarted extends PartyFavoritesEvent {
  const PartyFavoritesStarted();
}

class PartyFavoriteToggled extends PartyFavoritesEvent {
  const PartyFavoriteToggled(this.venueId);
  final String venueId;
  @override
  List<Object?> get props => [venueId];
}

class PartyFavoritesState extends Equatable {
  const PartyFavoritesState({
    this.status = PartyStatus.initial,
    this.venues = const [],
  });

  final PartyStatus status;
  final List<PartyVenueEntity> venues;

  bool isFavorite(String venueId) => venues.any((v) => v.id == venueId);

  @override
  List<Object?> get props => [status, venues];
}

class PartyFavoritesBloc extends Bloc<PartyFavoritesEvent, PartyFavoritesState> {
  PartyFavoritesBloc({
    required PartyGetFavoritesUseCase getFavorites,
    required PartyToggleFavoriteUseCase toggleFavorite,
  })  : _getFavorites = getFavorites,
        _toggleFavorite = toggleFavorite,
        super(const PartyFavoritesState()) {
    on<PartyFavoritesStarted>(_onStarted);
    on<PartyFavoriteToggled>(_onToggled);
  }

  final PartyGetFavoritesUseCase _getFavorites;
  final PartyToggleFavoriteUseCase _toggleFavorite;

  Future<void> _onStarted(
      PartyFavoritesStarted e, Emitter<PartyFavoritesState> emit) async {
    try {
      final list = await _getFavorites(const PartyNoParams());
      emit(PartyFavoritesState(status: PartyStatus.success, venues: list));
    } catch (_) {
      emit(const PartyFavoritesState(status: PartyStatus.failure));
    }
  }

  Future<void> _onToggled(
      PartyFavoriteToggled e, Emitter<PartyFavoritesState> emit) async {
    try {
      final list = await _toggleFavorite(e.venueId);
      emit(PartyFavoritesState(status: PartyStatus.success, venues: list));
    } catch (_) {
      // keep current state
    }
  }
}
