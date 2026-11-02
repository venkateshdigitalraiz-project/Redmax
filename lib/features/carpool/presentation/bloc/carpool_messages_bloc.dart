import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolMessagesEvent extends Equatable {
  const CarpoolMessagesEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolMessagesStarted extends CarpoolMessagesEvent {
  const CarpoolMessagesStarted();
}

class CarpoolMessagesTabChanged extends CarpoolMessagesEvent {
  const CarpoolMessagesTabChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class CarpoolMessagesState extends Equatable {
  const CarpoolMessagesState({
    this.status = CarpoolStatus.initial,
    this.tabIndex = 0,
    this.messages = const [],
  });

  final CarpoolStatus status;
  final int tabIndex;
  final List<CarpoolMessageEntity> messages;

  int get unreadCount => messages.fold(0, (s, m) => s + m.unreadCount);

  /// Tabs: 0 All, 1 Rides, 2 Support
  List<CarpoolMessageEntity> get visible {
    switch (tabIndex) {
      case 1:
        return messages
            .where((m) => m.category == CarpoolMessageCategory.rides)
            .toList();
      case 2:
        return messages
            .where((m) => m.category == CarpoolMessageCategory.support)
            .toList();
      default:
        return messages;
    }
  }

  CarpoolMessagesState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    List<CarpoolMessageEntity>? messages,
  }) => CarpoolMessagesState(
    status: status ?? this.status,
    tabIndex: tabIndex ?? this.tabIndex,
    messages: messages ?? this.messages,
  );

  @override
  List<Object?> get props => [status, tabIndex, messages];
}

class CarpoolMessagesBloc
    extends Bloc<CarpoolMessagesEvent, CarpoolMessagesState> {
  CarpoolMessagesBloc({required CarpoolGetMessagesUseCase getMessages})
    : _getMessages = getMessages,
      super(const CarpoolMessagesState()) {
    on<CarpoolMessagesStarted>(_onStarted);
    on<CarpoolMessagesTabChanged>(
      (e, emit) => emit(state.copyWith(tabIndex: e.index)),
    );
  }

  final CarpoolGetMessagesUseCase _getMessages;

  Future<void> _onStarted(
    CarpoolMessagesStarted e,
    Emitter<CarpoolMessagesState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final list = await _getMessages(const CarpoolNoParams());
      emit(state.copyWith(status: CarpoolStatus.success, messages: list));
    } catch (_) {
      emit(state.copyWith(status: CarpoolStatus.failure));
    }
  }
}
