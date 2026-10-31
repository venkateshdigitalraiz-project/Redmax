import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String authProvider; // 'phone', 'facebook', 'email', 'google', 'guest'
  final bool optOutMarketing;
  final List<String> holidayWith; // ['couple', 'friends', 'alone', 'family', 'pet']
  final String? homeExchangeInterest; // 'already_done', 'interested', 'no', 'dont_know'
  final double rating;
  final int ridesCompleted;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber = '',
    this.authProvider = 'phone',
    this.optOutMarketing = false,
    this.holidayWith = const [],
    this.homeExchangeInterest,
    this.rating = 5.0,
    this.ridesCompleted = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? authProvider,
    bool? optOutMarketing,
    List<String>? holidayWith,
    String? homeExchangeInterest,
    double? rating,
    int? ridesCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      optOutMarketing: optOutMarketing ?? this.optOutMarketing,
      holidayWith: holidayWith ?? this.holidayWith,
      homeExchangeInterest: homeExchangeInterest ?? this.homeExchangeInterest,
      rating: rating ?? this.rating,
      ridesCompleted: ridesCompleted ?? this.ridesCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
      'optOutMarketing': optOutMarketing,
      'holidayWith': holidayWith,
      'homeExchangeInterest': homeExchangeInterest,
      'rating': rating,
      'ridesCompleted': ridesCompleted,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      authProvider: json['authProvider'] as String? ?? 'phone',
      optOutMarketing: json['optOutMarketing'] as bool? ?? false,
      holidayWith: (json['holidayWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      homeExchangeInterest: json['homeExchangeInterest'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      ridesCompleted: (json['ridesCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phoneNumber,
        authProvider,
        optOutMarketing,
        holidayWith,
        homeExchangeInterest,
        rating,
        ridesCompleted,
      ];
}
