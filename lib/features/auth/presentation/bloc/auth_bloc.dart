import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/continue_as_guest_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/login_with_facebook_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_user_usecase.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/resend_phone_otp_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/update_profile_name_usecase.dart';
import '../../domain/usecases/update_survey_preferences_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final SendPhoneOtpUseCase sendPhoneOtpUseCase;
  final ResendPhoneOtpUseCase resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase verifyPhoneOtpUseCase;
  final LoginWithFacebookUseCase loginWithFacebookUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final RegisterWithEmailUseCase registerWithEmailUseCase;
  final RegisterUserUseCase registerUserUseCase;
  final ContinueAsGuestUseCase continueAsGuestUseCase;
  final UpdateProfileNameUseCase updateProfileNameUseCase;
  final UpdateSurveyPreferencesUseCase updateSurveyPreferencesUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.authRepository,
    GetCurrentUserUseCase? getCurrentUserUseCase,
    GetUserProfileUseCase? getUserProfileUseCase,
    SendPhoneOtpUseCase? sendPhoneOtpUseCase,
    ResendPhoneOtpUseCase? resendPhoneOtpUseCase,
    VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase,
    LoginWithFacebookUseCase? loginWithFacebookUseCase,
    LoginWithGoogleUseCase? loginWithGoogleUseCase,
    RegisterWithEmailUseCase? registerWithEmailUseCase,
    RegisterUserUseCase? registerUserUseCase,
    ContinueAsGuestUseCase? continueAsGuestUseCase,
    UpdateProfileNameUseCase? updateProfileNameUseCase,
    UpdateSurveyPreferencesUseCase? updateSurveyPreferencesUseCase,
    LogoutUseCase? logoutUseCase,
    UserProfile? initialUser,
  })  : getCurrentUserUseCase =
            getCurrentUserUseCase ?? GetCurrentUserUseCase(authRepository),
        getUserProfileUseCase =
            getUserProfileUseCase ?? GetUserProfileUseCase(authRepository),
        sendPhoneOtpUseCase =
            sendPhoneOtpUseCase ?? SendPhoneOtpUseCase(authRepository),
        resendPhoneOtpUseCase =
            resendPhoneOtpUseCase ?? ResendPhoneOtpUseCase(authRepository),
        verifyPhoneOtpUseCase =
            verifyPhoneOtpUseCase ?? VerifyPhoneOtpUseCase(authRepository),
        loginWithFacebookUseCase =
            loginWithFacebookUseCase ?? LoginWithFacebookUseCase(authRepository),
        loginWithGoogleUseCase =
            loginWithGoogleUseCase ?? LoginWithGoogleUseCase(authRepository),
        registerWithEmailUseCase =
            registerWithEmailUseCase ?? RegisterWithEmailUseCase(authRepository),
        registerUserUseCase =
            registerUserUseCase ?? RegisterUserUseCase(authRepository),
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
              : const AuthState(
                  status: AuthStatus.unauthenticated,
                  user: null,
                  isFirstTime: true,
                ),
        ) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<FetchUserProfileEvent>(_onFetchUserProfile);
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<ResendPhoneOtpEvent>(_onResendPhoneOtp);
    on<EditPhoneNumberEvent>(_onEditPhoneNumber);
    on<VerifyPhoneOtpEvent>(_onVerifyPhoneOtp);
    on<LoginWithFacebookEvent>(_onLoginWithFacebook);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<RegisterUserEvent>(_onRegisterUser);
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
    } else {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isFirstTime: true,
      ));
    }
  }

  Future<void> _onFetchUserProfile(
    FetchUserProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await getUserProfileUseCase();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isFirstTime: false,
      ));
    } catch (_) {
      // Retain current authenticated state
    }
  }

  Future<void> _onSendPhoneOtp(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));
    try {
      await sendPhoneOtpUseCase(event.phoneNumber);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isOtpSent: true,
        phoneNumber: event.phoneNumber,
        errorMessage: null,
        successMessage: 'OTP sent successfully!',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(
        status: AuthStatus.error,
        isOtpSent: false,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onResendPhoneOtp(
    ResendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));
    try {
      await resendPhoneOtpUseCase(event.phoneNumber);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isOtpSent: true,
        phoneNumber: event.phoneNumber,
        errorMessage: null,
        successMessage: 'OTP resent successfully!',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
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
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));
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
        successMessage: 'Welcome to Pathway!',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
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

  Future<void> _onRegisterUser(
    RegisterUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));
    try {
      await registerUserUseCase(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
      );
      emit(state.copyWith(
        status: AuthStatus.registered,
        clearUser: true,
        phoneNumber: event.phone.replaceAll(RegExp(r'^\+91'), '').trim(),
        isFirstTime: false,
        successMessage: 'Account created successfully! Please sign in.',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
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
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));
    try {
      await logoutUseCase();
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isFirstTime: false,
        isOtpSent: false,
        phoneNumber: '',
        successMessage: 'Logged out successfully',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      ));
    }
  }
}
