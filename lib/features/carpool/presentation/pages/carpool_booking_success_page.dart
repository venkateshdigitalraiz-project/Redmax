import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import '../bloc/carpool_bloc.dart';
import '../bloc/carpool_event.dart';
import '../bloc/carpool_state.dart';

/// Full-screen success state shown after a ride has been successfully booked.
class CarpoolBookingSuccessPage extends StatefulWidget {
  const CarpoolBookingSuccessPage({super.key});

  @override
  State<CarpoolBookingSuccessPage> createState() =>
      _CarpoolBookingSuccessPageState();
}

class _CarpoolBookingSuccessPageState extends State<CarpoolBookingSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Stagger the animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CarpoolBloc, CarpoolState>(
      builder: (context, state) {
        final ride = state.selectedRide;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark circle
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withAlpha(80),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'Ride Booked! 🎉',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your seat is confirmed. Have a safe journey!',
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Booking summary card
                  if (ride != null)
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorderLight
                                : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha(isDark ? 15 : 8),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Route summary
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ride.origin,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 24,
                                        height: 1.5,
                                        color: AppColors.textTertiary,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                      Container(
                                        width: 24,
                                        height: 1.5,
                                        color: AppColors.textTertiary,
                                      ),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF5B4F),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ride.destination,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.darkBorderLight
                                  : AppColors.borderLight,
                            ),
                            const SizedBox(height: 14),
                            // Details
                            _summaryRow(
                              icon: Icons.person_rounded,
                              label: 'Driver',
                              value: ride.driverName,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              icon: Icons.access_time_rounded,
                              label: 'Departure',
                              value: '${ride.departureTime}, ${ride.date}',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              icon: Icons.airline_seat_recline_normal_rounded,
                              label: 'Seats',
                              value: '${state.selectedSeats}',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Total Paid',
                              value:
                                  '₹${(ride.pricePerSeat * state.selectedSeats).toStringAsFixed(0)}',
                              isDark: isDark,
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 36),

                  // Go to Home button
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<CarpoolBloc>()
                              .add(const ResetCarpoolBookingEvent());
                          // Pop back to root (remove all carpool routes)
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? AppColors.primary : AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
