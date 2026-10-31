import 'package:equatable/equatable.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_filter.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_ride.dart';

/// Base class for all Carpool BLoC events.
abstract class CarpoolEvent extends Equatable {
  const CarpoolEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered to load all available rides on page entry.
class LoadCarpoolRidesEvent extends CarpoolEvent {
  const LoadCarpoolRidesEvent();
}

/// Triggered when the user types in the search bar.
class SearchCarpoolRidesEvent extends CarpoolEvent {
  final String query;

  const SearchCarpoolRidesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Triggered when a filter chip is tapped.
class ApplyCarpoolFilterEvent extends CarpoolEvent {
  final CarpoolFilter filter;

  const ApplyCarpoolFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Triggered when the user taps a ride card to view details.
class SelectCarpoolRideEvent extends CarpoolEvent {
  final CarpoolRide ride;

  const SelectCarpoolRideEvent(this.ride);

  @override
  List<Object?> get props => [ride];
}

/// Triggered when the user taps "Book Now".
class BookCarpoolRideEvent extends CarpoolEvent {
  final String rideId;
  final int seats;

  const BookCarpoolRideEvent({required this.rideId, required this.seats});

  @override
  List<Object?> get props => [rideId, seats];
}

/// Triggered when the seat count selector changes.
class CarpoolSeatCountChangedEvent extends CarpoolEvent {
  final int seats;

  const CarpoolSeatCountChangedEvent(this.seats);

  @override
  List<Object?> get props => [seats];
}

/// Triggered to reset the booking state (e.g. after success).
class ResetCarpoolBookingEvent extends CarpoolEvent {
  const ResetCarpoolBookingEvent();
}
