import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/continue_as_guest_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_facebook_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/update_profile_name_usecase.dart';
import '../../domain/usecases/update_survey_preferences_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SendPhoneOtpUseCase sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase verifyPhoneOtpUseCase;
  final LoginWithFacebookUseCase loginWithFacebookUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final RegisterWithEmailUseCase registerWithEmailUseCase;
  final ContinueAsGuestUseCase continueAsGuestUseCase;
  final UpdateProfileNameUseCase updateProfileNameUseCase;
  final UpdateSurveyPreferencesUseCase updateSurveyPreferencesUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.authRepository,
    GetCurrentUserUseCase? getCurrentUserUseCase,
    SendPhoneOtpUseCase? sendPhoneOtpUseCase,
    VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase,
    LoginWithFacebookUseCase? loginWithFacebookUseCase,
    LoginWithGoogleUseCase? loginWithGoogleUseCase,
    RegisterWithEmailUseCase? registerWithEmailUseCase,
    ContinueAsGuestUseCase? continueAsGuestUseCase,
    UpdateProfileNameUseCase? updateProfileNameUseCase,
    UpdateSurveyPreferencesUseCase? updateSurveyPreferencesUseCase,
    LogoutUseCase? logoutUseCase,
    UserProfile? initialUser,
  })  : getCurrentUserUseCase =
            getCurrentUserUseCase ?? GetCurrentUserUseCase(authRepository),
        sendPhoneOtpUseCase =
            sendPhoneOtpUseCase ?? SendPhoneOtpUseCase(authRepository),
        verifyPhoneOtpUseCase =
            verifyPhoneOtpUseCase ?? VerifyPhoneOtpUseCase(authRepository),
        loginWithFacebookUseCase =
            loginWithFacebookUseCase ?? LoginWithFacebookUseCase(authRepository),
        loginWithGoogleUseCase =
            loginWithGoogleUseCase ?? LoginWithGoogleUseCase(authRepository),
        registerWithEmailUseCase =
            registerWithEmailUseCase ?? RegisterWithEmailUseCase(authRepository),
        continueAsGuestUseCase =
            continueAsGuestUseCase ?? ContinueAsGuestUseCase(authRepository),
        updateProfileNameUseCase =
            updateProfileNameUseCase ?? UpdateProfileNameUseCase(authRepository),
        updateSurveyPreferencesUseCase = updateSurveyPreferencesUseCase ??
            UpdateSurveyPreferencesUseCase(authRepository),
        logoutUseCase = logoutUseCase ?? LogoutUseCase(authRepository),
        super(
          initialUser != null
              ? AuthState(
                  status: AuthStatus.authenticated,
                  user: initialUser,
                  isFirstTime: false,
                  phoneNumber: initialUser.phoneNumber,
                )
              : const AuthState(),
        ) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<EditPhoneNumberEvent>(_onEditPhoneNumber);
    on<VerifyPhoneOtpEvent>(_onVerifyPhoneOtp);
    on<LoginWithFacebookEvent>(_onLoginWithFacebook);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<ContinueAsGuestEvent>(_onContinueAsGuest);
    on<SaveHolidayPreferencesEvent>(_onSaveHolidayPreferences);
    on<SaveHomeExchangePreferenceEvent>(_onSaveHomeExchangePreference);
    on<SaveProfileNameEvent>(_onSaveProfileName);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = await getCurrentUserUseCase();
    if (user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
      ));
    } else if (state.status == AuthStatus.authenticated && state.user != null) {
      // Retain existing authenticated state
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isFirstTime: true,
      ));
    }
  }

  Future<void> _onSendPhoneOtp(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await sendPhoneOtpUseCase(event.phoneNumber);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isOtpSent: true,
        phoneNumber: event.phoneNumber,
        successMessage: 'OTP sent successfully to ${event.phoneNumber}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to send OTP: $e',
      ));
    }
  }

  void _onEditPhoneNumber(
    EditPhoneNumberEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      isOtpSent: false,
      errorMessage: null,
      successMessage: null,
    ));
  }

  Future<void> _onVerifyPhoneOtp(
    VerifyPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await verifyPhoneOtpUseCase(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        phoneNumber: event.phoneNumber,
        isFirstTime: false,
        isOtpSent: false,
        successMessage: 'OTP verified successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP: $e',
      ));
    }
  }

  Future<void> _onSaveProfileName(
    SaveProfileNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await updateProfileNameUseCase(
        firstName: event.firstName,
        lastName: event.lastName,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
        successMessage: 'Welcome to Carpool, ${user.firstName}!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to update name: $e',
      ));
    }
  }

  Future<void> _onLoginWithFacebook(
    LoginWithFacebookEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await loginWithFacebookUseCase();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Facebook login failed: $e',
      ));
    }
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await loginWithGoogleUseCase();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google login failed: $e',
      ));
    }
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await registerWithEmailUseCase(
        email: event.email,
        firstName: event.firstName,
        lastName: event.lastName,
        optOutMarketing: event.optOutMarketing,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed: $e',
      ));
    }
  }

  Future<void> _onContinueAsGuest(
    ContinueAsGuestEvent event,
    Emitter<AuthState> emit,
  ) async {
    final guest = await continueAsGuestUseCase();
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: guest,
      isFirstTime: false,
    ));
  }

  Future<void> _onSaveHolidayPreferences(
    SaveHolidayPreferencesEvent event,
    Emitter<AuthState> emit,
  ) async {
    await updateSurveyPreferencesUseCase(holidayWith: event.holidayWith);
    if (state.user != null) {
      final updated = state.user!.copyWith(holidayWith: event.holidayWith);
      emit(state.copyWith(user: updated));
    }
  }

  Future<void> _onSaveHomeExchangePreference(
    SaveHomeExchangePreferenceEvent event,
    Emitter<AuthState> emit,
  ) async {
    await updateSurveyPreferencesUseCase(homeExchangeInterest: event.interest);
    if (state.user != null) {
      final updated = state.user!.copyWith(homeExchangeInterest: event.interest);
      emit(state.copyWith(user: updated));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      isFirstTime: true,
      isOtpSent: false,
      phoneNumber: '',
    ));
  }
}
