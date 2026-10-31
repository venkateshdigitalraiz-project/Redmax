import 'package:equatable/equatable.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_filter.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_ride.dart';

/// Enumeration of all possible statuses for the Carpool BLoC.
enum CarpoolStatus { initial, loading, loaded, searching, error, booking, booked }

/// Immutable state for [CarpoolBloc].
class CarpoolState extends Equatable {
  final CarpoolStatus status;
  final List<CarpoolRide> rides;
  final List<CarpoolRide> filteredRides;
  final CarpoolRide? selectedRide;
  final CarpoolFilter filter;
  final String searchQuery;
  final int selectedSeats;
  final String? bookedRideId;
  final String? errorMessage;

  const CarpoolState({
    this.status = CarpoolStatus.initial,
    this.rides = const [],
    this.filteredRides = const [],
    this.selectedRide,
    this.filter = const CarpoolFilter(),
    this.searchQuery = '',
    this.selectedSeats = 1,
    this.bookedRideId,
    this.errorMessage,
  });

  CarpoolState copyWith({
    CarpoolStatus? status,
    List<CarpoolRide>? rides,
    List<CarpoolRide>? filteredRides,
    CarpoolRide? selectedRide,
    bool clearSelectedRide = false,
    CarpoolFilter? filter,
    String? searchQuery,
    int? selectedSeats,
    String? bookedRideId,
    bool clearBookedRideId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CarpoolState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
      filteredRides: filteredRides ?? this.filteredRides,
      selectedRide:
          clearSelectedRide ? null : (selectedRide ?? this.selectedRide),
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      bookedRideId: clearBookedRideId
          ? null
          : (bookedRideId ?? this.bookedRideId),
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        rides,
        filteredRides,
        selectedRide,
        filter,
        searchQuery,
        selectedSeats,
        bookedRideId,
        errorMessage,
      ];
}
