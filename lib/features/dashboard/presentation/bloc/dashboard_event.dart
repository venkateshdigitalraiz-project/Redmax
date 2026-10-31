import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardDataEvent extends DashboardEvent {
  const LoadDashboardDataEvent();
}

class RefreshDashboardDataEvent extends DashboardEvent {
  const RefreshDashboardDataEvent();
}
