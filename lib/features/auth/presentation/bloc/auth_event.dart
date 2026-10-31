import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SendPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  const SendPhoneOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class EditPhoneNumberEvent extends AuthEvent {}

class VerifyPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  const VerifyPhoneOtpEvent({required this.phoneNumber, required this.otp});

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class LoginWithFacebookEvent extends AuthEvent {}

class LoginWithGoogleEvent extends AuthEvent {}

class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String firstName;
  final String lastName;
  final bool optOutMarketing;

  const RegisterWithEmailEvent({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.optOutMarketing,
  });

  @override
  List<Object?> get props => [email, firstName, lastName, optOutMarketing];
}

class SaveProfileNameEvent extends AuthEvent {
  final String firstName;
  final String lastName;

  const SaveProfileNameEvent({
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [firstName, lastName];
}

class ContinueAsGuestEvent extends AuthEvent {}

class SaveHolidayPreferencesEvent extends AuthEvent {
  final List<String> holidayWith;
  const SaveHolidayPreferencesEvent(this.holidayWith);

  @override
  List<Object?> get props => [holidayWith];
}

class SaveHomeExchangePreferenceEvent extends AuthEvent {
  final String interest;
  const SaveHomeExchangePreferenceEvent(this.interest);

  @override
  List<Object?> get props => [interest];
}

class LogoutEvent extends AuthEvent {}
