import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/auth_welcome_page.dart';
import '../../features/auth/presentation/pages/name_input_page.dart';
import '../../features/carpool/presentation/pages/carpool_shell_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_shell_page.dart';
import '../../features/party_booking/presentation/pages/party_shell_page.dart';

/// Centralized route constants for type-safe and consistent navigation
class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String nameInput = '/name-input';
  static const String carpool = '/carpool';
  static const String party = '/party';
  static const String main = '/';
}

/// Helper class that adapts a stream (such as a BLoC stream) to a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Central application router adhering to Clean Architecture
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Creates and configures the GoRouter instance reactive to AuthBloc
  static GoRouter createRouter(AuthBloc authBloc) {
    final bool isInitiallyAuthenticated =
        authBloc.state.status == AuthStatus.authenticated ||
        authBloc.state.user != null;

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation:
          isInitiallyAuthenticated ? AppRoutes.main : AppRoutes.welcome,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final bool isAuthenticated =
            authState.status == AuthStatus.authenticated ||
            authState.user != null;
        final String location = state.matchedLocation;

        final bool isAuthRoute =
            location == AppRoutes.welcome || location == AppRoutes.nameInput;

        // If not authenticated, ensure user stays on auth pages
        if (!isAuthenticated) {
          if (!isAuthRoute) {
            return AppRoutes.welcome;
          }
          return null;
        }

        // If authenticated and currently on an auth page, redirect to main dashboard
        if (isAuthenticated && isAuthRoute) {
          return AppRoutes.main;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const AuthWelcomePage(),
        ),
        GoRoute(
          path: AppRoutes.nameInput,
          name: 'name-input',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final email = extra['email'] as String? ?? '';
            final optOutMarketing = extra['optOutMarketing'] as bool? ?? false;
            final phoneNumber = extra['phoneNumber'] as String? ?? '';
            return NameInputPage(
              email: email,
              optOutMarketing: optOutMarketing,
              phoneNumber: phoneNumber,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.main,
          name: 'main',
          builder: (context, state) => const DashboardShellPage(),
        ),
        GoRoute(
          path: AppRoutes.carpool,
          name: 'carpool',
          builder: (context, state) => const CarpoolShellPage(),
        ),
        GoRoute(
          path: AppRoutes.party,
          name: 'party',
          builder: (context, state) => const PartyShellPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
