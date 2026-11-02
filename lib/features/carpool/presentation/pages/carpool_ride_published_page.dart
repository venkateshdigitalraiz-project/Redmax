import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';

import '../../../../core/carpool_core.dart';
import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_my_rides_bloc.dart';
import '../bloc/carpool_nav_cubit.dart';
import 'carpool_shell_page.dart';

class CarpoolRidePublishedPage extends StatelessWidget {
  const CarpoolRidePublishedPage({super.key, required this.ride});
  final CarpoolRideEntity ride;

  void _navigateToMyRides(BuildContext context) {
    try {
      context.read<CarpoolMyRidesBloc>().add(
        const CarpoolMyRidesStarted(),
      );
    } catch (_) {}
    try {
      context.read<CarpoolNavCubit>().select(1);
    } catch (_) {}
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CarpoolShellPage(initialIndex: 1),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.read<CarpoolMyRidesBloc>();
      context.read<CarpoolNavCubit>();
      return _buildScaffold(context);
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return MultiBlocProvider(
        providers: [
          BlocProvider<CarpoolNavCubit>(create: (_) => CarpoolNavCubit(1)),
          BlocProvider<CarpoolMyRidesBloc>(
            create: (_) => CarpoolMyRidesBloc(
              getMyRides: CarpoolGetMyRidesUseCase(repository),
              cancelRide: CarpoolCancelRideUseCase(repository),
            )..add(const CarpoolMyRidesStarted()),
          ),
        ],
        child: Builder(
          builder: (innerContext) => _buildScaffold(innerContext),
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateToMyRides(context);
        }
      },
      child: Scaffold(
        body: CarpoolGradientBackground(
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: CarpoolConfettiPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 130,
                        height: 130,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(.25),
                            width: 4,
                          ),
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Ride Published!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your ride has been successfully\npublished.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 22),
                      CarpoolCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.success,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ride.from} → ${ride.to}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CarpoolFormatters.headline(ride.departure),
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_alt_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ride.seats} Seats • ${CarpoolFormatters.rupee(ride.pricePerSeat)}/seat',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      CarpoolPrimaryButton(
                        label: 'View My Ride',
                        onPressed: () => _navigateToMyRides(context),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Share link copied for ${ride.from} → ${ride.to}',
                            ),
                          ),
                        ),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.6,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.share_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Share Ride',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
