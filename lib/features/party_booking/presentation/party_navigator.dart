import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/party_favorites_bloc.dart';
import 'bloc/party_my_bookings_bloc.dart';
import 'bloc/party_nav_cubit.dart';

/// In-module navigation helper.
///
/// Pushed pages live outside the shell's widget subtree, so the module-wide
/// blocs are forwarded with `BlocProvider.value`. Child routes are tagged so
/// [popToShell] never pops the host app's own routes.
class PartyNavigator {
  PartyNavigator._();

  static const String childRouteName = 'party_child';

  static Widget _scoped(BuildContext context, Widget page) {
    try {
      final favorites = context.read<PartyFavoritesBloc>();
      final bookings = context.read<PartyMyBookingsBloc>();
      final nav = context.read<PartyNavCubit>();
      return MultiBlocProvider(
        providers: [
          BlocProvider<PartyFavoritesBloc>.value(value: favorites),
          BlocProvider<PartyMyBookingsBloc>.value(value: bookings),
          BlocProvider<PartyNavCubit>.value(value: nav),
        ],
        child: page,
      );
    } catch (_) {
      return page;
    }
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    final scoped = _scoped(context, page);
    return Navigator.of(context).push<T>(MaterialPageRoute<T>(
      settings: const RouteSettings(name: childRouteName),
      builder: (_) => scoped,
    ));
  }

  static Future<T?> replace<T>(BuildContext context, Widget page) {
    final scoped = _scoped(context, page);
    return Navigator.of(context).pushReplacement<T, dynamic>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: childRouteName),
        builder: (_) => scoped,
      ),
    );
  }

  /// Pops every Party child page and lands back on the Party shell.
  static void popToShell(BuildContext context) {
    Navigator.of(context)
        .popUntil((route) => route.settings.name != childRouteName);
  }
}
