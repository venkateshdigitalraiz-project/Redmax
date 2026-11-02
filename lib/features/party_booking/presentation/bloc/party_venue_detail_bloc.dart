import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../../domain/usecases/party_usecases.dart';

abstract class PartyVenueDetailEvent extends Equatable {
  const PartyVenueDetailEvent();
  @override
  List<Object?> get props => [];
}

class PartyVenueDetailStarted extends PartyVenueDetailEvent {
  const PartyVenueDetailStarted(this.venueId);
  final String venueId;
  @override
  List<Object?> get props => [venueId];
}

class PartyVenueDetailImageChanged extends PartyVenueDetailEvent {
  const PartyVenueDetailImageChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class PartyVenueDetailReadMoreToggled extends PartyVenueDetailEvent {
  const PartyVenueDetailReadMoreToggled();
}

class PartyVenueDetailState extends Equatable {
  const PartyVenueDetailState({
    this.status = PartyStatus.initial,
    this.venue,
    this.imageIndex = 0,
    this.expanded = false,
    this.error,
  });

  final PartyStatus status;
  final PartyVenueEntity? venue;
  final int imageIndex;
  final bool expanded;
  final String? error;

  PartyVenueDetailState copyWith({
    PartyStatus? status,
    PartyVenueEntity? venue,
    int? imageIndex,
    bool? expanded,
    String? error,
  }) =>
      PartyVenueDetailState(
        status: status ?? this.status,
        venue: venue ?? this.venue,
        imageIndex: imageIndex ?? this.imageIndex,
        expanded: expanded ?? this.expanded,
        error: error,
      );

  @override
  List<Object?> get props => [status, venue, imageIndex, expanded, error];
}

class PartyVenueDetailBloc
    extends Bloc<PartyVenueDetailEvent, PartyVenueDetailState> {
  PartyVenueDetailBloc({required PartyGetVenueUseCase getVenue})
      : _getVenue = getVenue,
        super(const PartyVenueDetailState()) {
    on<PartyVenueDetailStarted>(_onStarted);
    on<PartyVenueDetailImageChanged>(
        (e, emit) => emit(state.copyWith(imageIndex: e.index)));
    on<PartyVenueDetailReadMoreToggled>(
        (e, emit) => emit(state.copyWith(expanded: !state.expanded)));
  }

  final PartyGetVenueUseCase _getVenue;

  Future<void> _onStarted(PartyVenueDetailStarted e,
      Emitter<PartyVenueDetailState> emit) async {
    emit(state.copyWith(status: PartyStatus.loading));
    try {
      final venue = await _getVenue(e.venueId);
      emit(state.copyWith(status: PartyStatus.success, venue: venue));
    } catch (err) {
      emit(state.copyWith(status: PartyStatus.failure, error: '$err'));
    }
  }
}
