import 'package:equatable/equatable.dart';

enum ActivityStatus {
  upcoming,
  delivered,
  completed,
  cancelled,
}

enum ActivityType {
  carpool,
  delivery,
  taxi,
  rental,
}

class RecentActivityEntry extends Equatable {
  final String id;
  final String title;
  final String timestampText;
  final String subtitle;
  final ActivityStatus status;
  final ActivityType type;

  const RecentActivityEntry({
    required this.id,
    required this.title,
    required this.timestampText,
    required this.subtitle,
    required this.status,
    required this.type,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        timestampText,
        subtitle,
        status,
        type,
      ];
}
