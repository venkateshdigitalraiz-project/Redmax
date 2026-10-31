import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticated,
  loading,
  error,
  otpVerified,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;
  final String? successMessage;
  final bool isFirstTime;
  final bool isOtpSent;
  final String phoneNumber;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.isFirstTime = true,
    this.isOtpSent = false,
    this.phoneNumber = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
    String? successMessage,
    bool? isFirstTime,
    bool? isOtpSent,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        successMessage,
        isFirstTime,
        isOtpSent,
        phoneNumber,
      ];
}
