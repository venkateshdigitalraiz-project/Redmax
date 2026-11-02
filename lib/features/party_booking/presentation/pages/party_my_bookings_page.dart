import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/party_colors.dart';
import '../../core/party_formatters.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_my_bookings_bloc.dart';
import '../bloc/party_nav_cubit.dart';
import '../widgets/party_widgets.dart';
import 'party_booking_page.dart' show partyPaymentLabel;

/// Screen 5: "My Bookings".
class PartyMyBookingsPage extends StatelessWidget {
  const PartyMyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartyMyBookingsBloc, PartyMyBookingsState>(
      listenWhen: (p, c) => c.message != null && p.message != c.message,
      listener: (context, s) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.message!))),
      builder: (context, state) {
        final bookings = state.visible;
        return Column(
          children: [
            PartyHeaderBar(
              title: 'My Bookings',
              onBack: () => context.read<PartyNavCubit>().select(0),
            ),
            _Tabs(
              index: state.tabIndex,
              onChanged: (i) => context
                  .read<PartyMyBookingsBloc>()
                  .add(PartyMyBookingsTabChanged(i)),
            ),
            Expanded(
              child: state.status == PartyStatus.loading && state.bookings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : bookings.isEmpty
                      ? Center(
                          child: Text(
                            state.tabIndex == 0
                                ? 'No upcoming bookings.\nPick a venue and plan your party!'
                                : 'No past bookings yet.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) =>
                              _BookingCard(booking: bookings[i]),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i, String label) {
      final selected = index == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? PartyColors.primary : PartyColors.border,
                  width: selected ? 2.4 : 1,
                ),
              ),
            ),
            child: Text(label,
                style: AppTypography.bodyLarge.copyWith(
                  color: selected ? PartyColors.primary : PartyColors.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Row(children: [tab(0, 'Upcoming'), tab(1, 'Past')]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final PartyBookingEntity booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: PartyColors.primary.withOpacity(.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartyImage(
            url: booking.venue.coverImage,
            seed: booking.venue.id.hashCode,
            width: 112,
            height: 128,
            radius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PartyStatusChip(status: booking.status),
                const SizedBox(height: 6),
                Text(booking.venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w800)),
                PartyMetaRow(
                    icon: Icons.calendar_month_rounded,
                    text: PartyFormatters.date(booking.date)),
                PartyMetaRow(
                    icon: Icons.access_time_rounded, text: booking.timeSlot),
                PartyMetaRow(
                    icon: Icons.groups_rounded,
                    text: PartyFormatters.guests(booking.guests)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: PartyPillButton(
                    label: 'View Details →',
                    height: 34,
                    onTap: () => _showDetails(context, booking),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, PartyBookingEntity b) {
    final bloc = context.read<PartyMyBookingsBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheet) {
        Widget row(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 96,
                      child: Text(k, style: AppTypography.bodyMedium)),
                  Expanded(
                    child: Text(v,
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(b.venue.name,
                          style: AppTypography.titleLarge),
                    ),
                    PartyStatusChip(status: b.status),
                  ],
                ),
                const SizedBox(height: 10),
                row('Location', b.venue.location),
                row('Date', PartyFormatters.date(b.date)),
                row('Time', b.timeSlot),
                row('Guests', '${b.guests}'),
                row('Booked by', '${b.guestName} • +91 ${b.phone}'),
                row('Payment', partyPaymentLabel(b.paymentMethod)),
                row('Advance paid', PartyFormatters.rupee(b.advanceAmount)),
                row('Total', PartyFormatters.rupee(b.totalAmount)),
                if (b.isUpcoming) ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Cancel Booking',
                    backgroundColor: PartyColors.errorSurface,
                    textColor: PartyColors.error,
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: sheet,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel this booking?'),
                          content: Text(
                              '${b.venue.name} on ${PartyFormatters.date(b.date)} will be cancelled.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep booking')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Cancel booking',
                                    style: TextStyle(color: PartyColors.error))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        bloc.add(PartyMyBookingsCancelPressed(b.id));
                        if (sheet.mounted) Navigator.pop(sheet);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
