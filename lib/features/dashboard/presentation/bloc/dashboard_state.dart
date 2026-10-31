import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardData? data;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
