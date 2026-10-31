import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/storage/storedlocal.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/entities/user_profile.dart';
import 'features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_with_facebook_usecase.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_with_email_usecase.dart';
import 'features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'features/auth/domain/usecases/update_profile_name_usecase.dart';
import 'features/auth/domain/usecases/update_survey_preferences_usecase.dart';
import 'features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storedLocal = StoredLocal();
  await storedLocal.init();
  final initialUser = await storedLocal.getUser();

  runApp(PathwayApp(initialUser: initialUser, storedLocal: storedLocal));
}

class PathwayApp extends StatefulWidget {
  final AuthBloc? authBloc;
  final DashboardBloc? dashboardBloc;
  final UserProfile? initialUser;
  final StoredLocal? storedLocal;

  const PathwayApp({
    super.key,
    this.authBloc,
    this.dashboardBloc,
    this.initialUser,
    this.storedLocal,
  });

  @override
  State<PathwayApp> createState() => _PathwayAppState();
}

class _PathwayAppState extends State<PathwayApp> {
  late final AuthBloc _authBloc;
  late final DashboardBloc _dashboardBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final storedLocal = widget.storedLocal ?? StoredLocal();
    final authLocalDataSource = AuthLocalDataSourceImpl(
      storedLocal: storedLocal,
    );
    final authRepository = AuthRepositoryImpl(
      localDataSource: authLocalDataSource,
    );

    _authBloc = widget.authBloc ??
        (AuthBloc(
          authRepository: authRepository,
          getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
          sendPhoneOtpUseCase: SendPhoneOtpUseCase(authRepository),
          verifyPhoneOtpUseCase: VerifyPhoneOtpUseCase(authRepository),
          loginWithFacebookUseCase: LoginWithFacebookUseCase(authRepository),
          loginWithGoogleUseCase: LoginWithGoogleUseCase(authRepository),
          registerWithEmailUseCase: RegisterWithEmailUseCase(authRepository),
          continueAsGuestUseCase: ContinueAsGuestUseCase(authRepository),
          updateProfileNameUseCase: UpdateProfileNameUseCase(authRepository),
          updateSurveyPreferencesUseCase: UpdateSurveyPreferencesUseCase(
            authRepository,
          ),
          logoutUseCase: LogoutUseCase(authRepository),
          initialUser: widget.initialUser,
        )..add(CheckAuthStatusEvent()));

    final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl();
    final dashboardRepository = DashboardRepositoryImpl(
      remoteDataSource: dashboardRemoteDataSource,
    );
    final getDashboardDataUseCase = GetDashboardDataUseCase(dashboardRepository);

    _dashboardBloc = widget.dashboardBloc ??
        (DashboardBloc(
          getDashboardDataUseCase: getDashboardDataUseCase,
        )..add(const LoadDashboardDataEvent()));

    _router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    if (widget.authBloc == null) {
      _authBloc.close();
    }
    if (widget.dashboardBloc == null) {
      _dashboardBloc.close();
    }
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<DashboardBloc>.value(value: _dashboardBloc),
      ],
      child: MaterialApp.router(
        title: 'Pathway',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
