import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';
import 'package:pathway/features/party_booking/core/party_colors.dart';

import '../../core/party_formatters.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_my_bookings_bloc.dart';
import '../bloc/party_nav_cubit.dart';
import '../party_navigator.dart';
import '../widgets/party_painters.dart';
import '../widgets/party_widgets.dart';

/// Screen 6: "Booking Confirmed!"
class PartyBookingConfirmedPage extends StatelessWidget {
  const PartyBookingConfirmedPage({super.key, required this.booking});
  final PartyBookingEntity booking;

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 22, color: PartyColors.text),
        const SizedBox(width: 14),
        Text(
          text,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _viewBooking(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: PartyConfettiPainter()),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: PartyColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PartyColors.success.withOpacity(.4),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Booking Confirmed!',
                    style: AppTypography.displayMedium.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your party is all set. Get ready to\ncelebrate!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w400,
                        color: PartyColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: PartyColors.tile,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _row(
                          Icons.calendar_month_rounded,
                          PartyFormatters.date(booking.date),
                        ),
                        _row(Icons.access_time_rounded, booking.timeSlot),
                        _row(
                          Icons.groups_rounded,
                          PartyFormatters.guests(booking.guests),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'View Booking Details',
                          backgroundColor: PartyColors.primary,
                          onPressed: () => _viewBooking(context),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Share Booking',
                          icon: Icons.ios_share_rounded,
                          backgroundColor: Colors.white,
                          textColor: PartyColors.primary,
                          borderSide: const BorderSide(
                            color: PartyColors.primary,
                            width: 1.4,
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${booking.venue.name} • ${PartyFormatters.date(booking.date)} • ${booking.timeSlot} • ${booking.guests} guests',
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking details copied'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const PartyCrowd(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBooking(BuildContext context) {
    context.read<PartyMyBookingsBloc>().add(const PartyMyBookingsStarted());
    context.read<PartyNavCubit>().select(1);
    PartyNavigator.popToShell(context);
  }
}
