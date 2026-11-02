import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolProfileEvent extends Equatable {
  const CarpoolProfileEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolProfileStarted extends CarpoolProfileEvent {
  const CarpoolProfileStarted();
}

class CarpoolProfileNotificationsToggled extends CarpoolProfileEvent {
  const CarpoolProfileNotificationsToggled(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

class CarpoolProfileState extends Equatable {
  const CarpoolProfileState({
    this.status = CarpoolStatus.initial,
    this.user,
    this.notificationsEnabled = true,
  });

  final CarpoolStatus status;
  final CarpoolUserEntity? user;
  final bool notificationsEnabled;

  CarpoolProfileState copyWith({
    CarpoolStatus? status,
    CarpoolUserEntity? user,
    bool? notificationsEnabled,
  }) =>
      CarpoolProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  List<Object?> get props => [status, user, notificationsEnabled];
}

class CarpoolProfileBloc
    extends Bloc<CarpoolProfileEvent, CarpoolProfileState> {
  CarpoolProfileBloc({required CarpoolGetUserUseCase getUser})
      : _getUser = getUser,
        super(const CarpoolProfileState()) {
    on<CarpoolProfileStarted>(_onStarted);
    on<CarpoolProfileNotificationsToggled>(
        (e, emit) => emit(state.copyWith(notificationsEnabled: e.enabled)));
  }

  final CarpoolGetUserUseCase _getUser;

  Future<void> _onStarted(
      CarpoolProfileStarted e, Emitter<CarpoolProfileState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final user = await _getUser(const CarpoolNoParams());
      emit(state.copyWith(status: CarpoolStatus.success, user: user));
    } catch (_) {
      emit(state.copyWith(status: CarpoolStatus.failure));
    }
  }
}
