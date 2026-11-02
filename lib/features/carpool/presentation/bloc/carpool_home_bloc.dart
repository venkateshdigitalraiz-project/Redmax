import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolHomeEvent extends Equatable {
  const CarpoolHomeEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolHomeStarted extends CarpoolHomeEvent {
  const CarpoolHomeStarted();
}

class CarpoolHomeState extends Equatable {
  const CarpoolHomeState({
    this.status = CarpoolStatus.initial,
    this.user,
    this.routes = const [],
    this.error,
  });

  final CarpoolStatus status;
  final CarpoolUserEntity? user;
  final List<CarpoolPopularRouteEntity> routes;
  final String? error;

  CarpoolHomeState copyWith({
    CarpoolStatus? status,
    CarpoolUserEntity? user,
    List<CarpoolPopularRouteEntity>? routes,
    String? error,
  }) => CarpoolHomeState(
    status: status ?? this.status,
    user: user ?? this.user,
    routes: routes ?? this.routes,
    error: error,
  );

  @override
  List<Object?> get props => [status, user, routes, error];
}

class CarpoolHomeBloc extends Bloc<CarpoolHomeEvent, CarpoolHomeState> {
  CarpoolHomeBloc({
    required CarpoolGetUserUseCase getUser,
    required CarpoolGetPopularRoutesUseCase getPopularRoutes,
  }) : _getUser = getUser,
       _getPopularRoutes = getPopularRoutes,
       super(const CarpoolHomeState()) {
    on<CarpoolHomeStarted>(_onStarted);
  }

  final CarpoolGetUserUseCase _getUser;
  final CarpoolGetPopularRoutesUseCase _getPopularRoutes;

  Future<void> _onStarted(
    CarpoolHomeStarted event,
    Emitter<CarpoolHomeState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final results = await Future.wait([
        _getUser(const CarpoolNoParams()),
        _getPopularRoutes(const CarpoolNoParams()),
      ]);
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          user: results[0] as CarpoolUserEntity,
          routes: results[1] as List<CarpoolPopularRouteEntity>,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, error: '$e'));
    }
  }
}
