import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/features/carpool/presentation/pages/carpool_publish_ride_page.dart';

import '../../../../core/carpool_core.dart';
import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_find_ride_bloc.dart';
import '../bloc/carpool_home_bloc.dart';
import '../bloc/carpool_messages_bloc.dart';
import '../bloc/carpool_my_rides_bloc.dart';
import '../bloc/carpool_nav_cubit.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../bloc/carpool_profile_bloc.dart';
import '../bloc/carpool_wallet_bloc.dart';
import 'carpool_home_page.dart';
import 'carpool_messages_page.dart';
import 'carpool_my_rides_page.dart';
import 'carpool_offer_ride_page.dart';
import 'carpool_profile_page.dart';

/// Hosts the 4 tabs + the centre "+" (Offer a Ride) button.
/// Fully self-contained Clean Architecture setup with BLoC without external DI.
class CarpoolShellPage extends StatelessWidget {
  final int initialIndex;
  const CarpoolShellPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = CarpoolMockDataSource();
    final repository = CarpoolRepositoryImpl(remoteDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<CarpoolNavCubit>(
          create: (_) => CarpoolNavCubit(initialIndex),
        ),
        BlocProvider<CarpoolHomeBloc>(
          create: (_) => CarpoolHomeBloc(
            getUser: CarpoolGetUserUseCase(repository),
            getPopularRoutes: CarpoolGetPopularRoutesUseCase(repository),
          )..add(const CarpoolHomeStarted()),
        ),
        BlocProvider<CarpoolFindRideBloc>(
          create: (_) => CarpoolFindRideBloc(
            searchRides: CarpoolSearchRidesUseCase(repository),
            bookRide: CarpoolBookRideUseCase(repository),
          ),
        ),
        BlocProvider<CarpoolMyRidesBloc>(
          create: (_) => CarpoolMyRidesBloc(
            getMyRides: CarpoolGetMyRidesUseCase(repository),
            cancelRide: CarpoolCancelRideUseCase(repository),
          )..add(const CarpoolMyRidesStarted()),
        ),
        BlocProvider<CarpoolMessagesBloc>(
          create: (_) => CarpoolMessagesBloc(
            getMessages: CarpoolGetMessagesUseCase(repository),
          )..add(const CarpoolMessagesStarted()),
        ),
        BlocProvider<CarpoolProfileBloc>(
          create: (_) =>
              CarpoolProfileBloc(getUser: CarpoolGetUserUseCase(repository))
                ..add(const CarpoolProfileStarted()),
        ),
        BlocProvider<CarpoolWalletBloc>(
          create: (_) => CarpoolWalletBloc(
            getWallet: CarpoolGetWalletUseCase(repository),
            addMoney: CarpoolAddMoneyUseCase(repository),
          )..add(const CarpoolWalletStarted()),
        ),
        BlocProvider<CarpoolOfferRideBloc>(
          create: (_) => CarpoolOfferRideBloc(
            publishRide: CarpoolPublishRideUseCase(repository),
          ),
        ),
      ],
      child: const _CarpoolShellView(),
    );
  }
}

class _CarpoolShellView extends StatelessWidget {
  const _CarpoolShellView();

  static const List<Widget> _tabs = [
    CarpoolHomePage(),
    CarpoolMyRidesPage(),
    CarpoolPublishRidePage(),
    CarpoolMessagesPage(),
    CarpoolProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarpoolNavCubit, int>(
      builder: (context, index) {
        return Scaffold(
          body: CarpoolGradientBackground(
            child: IndexedStack(index: index, children: _tabs),
          ),
          bottomNavigationBar:
              BlocBuilder<CarpoolMessagesBloc, CarpoolMessagesState>(
                builder: (context, messages) => CarpoolBottomNav(
                  currentIndex: index,
                  unreadMessages: messages.unreadCount,
                  onTap: context.read<CarpoolNavCubit>().select,
                  onCenterTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CarpoolOfferRidePage(),
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }
}
