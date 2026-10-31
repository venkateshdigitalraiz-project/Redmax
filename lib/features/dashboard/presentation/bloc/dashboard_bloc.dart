import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  DashboardBloc({required this.getDashboardDataUseCase})
      : super(const DashboardState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshDashboardDataEvent>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await getDashboardDataUseCase();
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        data: data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await getDashboardDataUseCase();
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        data: data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
