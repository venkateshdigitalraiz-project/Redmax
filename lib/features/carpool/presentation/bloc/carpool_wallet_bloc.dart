import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';

abstract class CarpoolWalletEvent extends Equatable {
  const CarpoolWalletEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolWalletStarted extends CarpoolWalletEvent {
  const CarpoolWalletStarted();
}

class CarpoolWalletAddMoneyPressed extends CarpoolWalletEvent {
  const CarpoolWalletAddMoneyPressed(this.amount);
  final double amount;
  @override
  List<Object?> get props => [amount];
}

class CarpoolWalletState extends Equatable {
  const CarpoolWalletState({
    this.status = CarpoolStatus.initial,
    this.wallet,
    this.message,
  });

  final CarpoolStatus status;
  final CarpoolWalletEntity? wallet;
  final String? message;

  CarpoolWalletState copyWith(
          {CarpoolStatus? status, CarpoolWalletEntity? wallet, String? message}) =>
      CarpoolWalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        message: message,
      );

  @override
  List<Object?> get props => [status, wallet, message];
}

class CarpoolWalletBloc extends Bloc<CarpoolWalletEvent, CarpoolWalletState> {
  CarpoolWalletBloc({
    required CarpoolGetWalletUseCase getWallet,
    required CarpoolAddMoneyUseCase addMoney,
  })  : _getWallet = getWallet,
        _addMoney = addMoney,
        super(const CarpoolWalletState()) {
    on<CarpoolWalletStarted>(_onStarted);
    on<CarpoolWalletAddMoneyPressed>(_onAddMoney);
  }

  final CarpoolGetWalletUseCase _getWallet;
  final CarpoolAddMoneyUseCase _addMoney;

  Future<void> _onStarted(
      CarpoolWalletStarted e, Emitter<CarpoolWalletState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final wallet = await _getWallet(const CarpoolNoParams());
      emit(state.copyWith(status: CarpoolStatus.success, wallet: wallet));
    } catch (err) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: '$err'));
    }
  }

  Future<void> _onAddMoney(CarpoolWalletAddMoneyPressed e,
      Emitter<CarpoolWalletState> emit) async {
    try {
      final wallet = await _addMoney(e.amount);
      emit(state.copyWith(
          status: CarpoolStatus.success,
          wallet: wallet,
          message: 'Money added to your wallet'));
    } catch (err) {
      emit(state.copyWith(message: '$err'));
    }
    emit(state.copyWith());
  }
}
