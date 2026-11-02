import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_injector.dart';
import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_home_bloc.dart';
import '../bloc/party_my_bookings_bloc.dart';
import '../bloc/party_nav_cubit.dart';
import '../widgets/party_widgets.dart';
import 'party_favorites_page.dart';
import 'party_home_page.dart';
import 'party_my_bookings_page.dart';
import 'party_profile_page.dart';

/// Entry point of the Party Booking module (route: `/party`).
/// Provides all module-wide blocs and hosts the 4 bottom tabs.
class PartyShellPage extends StatelessWidget {
  const PartyShellPage({super.key});

  static const List<Widget> _tabs = [
    PartyHomePage(),
    PartyMyBookingsPage(),
    PartyFavoritesPage(),
    PartyProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final di = PartyInjector.I;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PartyNavCubit()),
        BlocProvider(create: (_) => di.homeBloc()..add(const PartyHomeStarted())),
        BlocProvider(
            create: (_) => di.favoritesBloc()..add(const PartyFavoritesStarted())),
        BlocProvider(
            create: (_) =>
                di.myBookingsBloc()..add(const PartyMyBookingsStarted())),
      ],
      child: BlocBuilder<PartyNavCubit, int>(
        builder: (context, index) {
          return PopScope(
            canPop: index == 0,
            onPopInvoked: (didPop) {
              if (!didPop) context.read<PartyNavCubit>().select(0);
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: IndexedStack(index: index, children: _tabs),
              bottomNavigationBar: PartyBottomNav(
                currentIndex: index,
                onTap: context.read<PartyNavCubit>().select,
              ),
            ),
          );
        },
      ),
    );
  }
}
