import 'package:equatable/equatable.dart';

class ActiveRideBanner extends Equatable {
  final String id;
  final String title;
  final String origin;
  final String destination;
  final String timeRemaining;
  final String? carImageUrl;

  const ActiveRideBanner({
    required this.id,
    this.title = 'Active Ride',
    required this.origin,
    required this.destination,
    required this.timeRemaining,
    this.carImageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        origin,
        destination,
        timeRemaining,
        carImageUrl,
      ];
}
