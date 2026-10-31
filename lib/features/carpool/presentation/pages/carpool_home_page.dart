import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/features/carpool/data/datasources/carpool_remote_datasource.dart';
import 'package:pathway/features/carpool/data/repositories/carpool_repository_impl.dart';
import 'package:pathway/features/carpool/domain/usecases/book_ride_usecase.dart';
import 'package:pathway/features/carpool/domain/usecases/get_available_rides_usecase.dart';
import 'package:pathway/features/carpool/domain/usecases/search_rides_usecase.dart';
import '../bloc/carpool_bloc.dart';
import '../bloc/carpool_event.dart';
import '../bloc/carpool_state.dart';
import '../widgets/carpool_filter_chips.dart';
import '../widgets/carpool_ride_card.dart';
import '../widgets/carpool_search_bar.dart';
import 'carpool_ride_detail_page.dart';

/// Entry point for the Carpool feature. Creates its own [BlocProvider].
class CarpoolHomePage extends StatelessWidget {
  const CarpoolHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteDs = CarpoolRemoteDataSourceImpl();
    final repo = CarpoolRepositoryImpl(remoteDataSource: remoteDs);

    return BlocProvider(
      create: (_) => CarpoolBloc(
        getAvailableRidesUseCase: GetAvailableRidesUseCase(repo),
        searchRidesUseCase: SearchRidesUseCase(repo),
        bookRideUseCase: BookRideUseCase(repo),
      )..add(const LoadCarpoolRidesEvent()),
      child: const _CarpoolHomeView(),
    );
  }
}

class _CarpoolHomeView extends StatefulWidget {
  const _CarpoolHomeView();

  @override
  State<_CarpoolHomeView> createState() => _CarpoolHomeViewState();
}

class _CarpoolHomeViewState extends State<_CarpoolHomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 14),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<CarpoolBloc, CarpoolState>(
              buildWhen: (prev, curr) => prev.searchQuery != curr.searchQuery,
              builder: (context, state) {
                return CarpoolSearchBar(
                  onChanged: (q) => context.read<CarpoolBloc>().add(
                    SearchCarpoolRidesEvent(q),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          BlocBuilder<CarpoolBloc, CarpoolState>(
            buildWhen: (prev, curr) => prev.filter != curr.filter,
            builder: (context, state) {
              return CarpoolFilterChips(
                currentFilter: state.filter,
                onFilterChanged: (f) =>
                    context.read<CarpoolBloc>().add(ApplyCarpoolFilterEvent(f)),
              );
            },
          ),
          const SizedBox(height: 12),
          // Ride list
          Expanded(
            child: BlocConsumer<CarpoolBloc, CarpoolState>(
              listenWhen: (prev, curr) => curr.status == CarpoolStatus.error,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Something went wrong'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              buildWhen: (prev, curr) =>
                  prev.status != curr.status ||
                  prev.filteredRides != curr.filteredRides,
              builder: (context, state) {
                if (state.status == CarpoolStatus.initial ||
                    state.status == CarpoolStatus.loading) {
                  return _buildShimmer(isDark);
                }
                if (state.filteredRides.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<CarpoolBloc>().add(
                      const LoadCarpoolRidesEvent(),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 100),
                    itemCount: state.filteredRides.length,
                    itemBuilder: (context, index) {
                      final ride = state.filteredRides[index];
                      return CarpoolRideCard(
                        ride: ride,
                        onTap: () {
                          context.read<CarpoolBloc>().add(
                            SelectCarpoolRideEvent(ride),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<CarpoolBloc>(),
                                child: const CarpoolRideDetailPage(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🚗 Offer a Ride feature coming soon!'),
              backgroundColor: isDark
                  ? AppColors.darkCard
                  : AppColors.textPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Offer a Ride',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carpool Rides',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share your journey, save together',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(200),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerOpacity = 0.4 + (_shimmerController.value * 0.6);
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            height: 150,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withAlpha((shimmerOpacity * 255).toInt())
                  : AppColors.borderLight.withAlpha(
                      (shimmerOpacity * 255).toInt(),
                    ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.carpoolBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 36,
              color: AppColors.carpoolIcon,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No rides found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search or adjust filters',
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                context.read<CarpoolBloc>().add(const LoadCarpoolRidesEvent()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Show All Rides',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
