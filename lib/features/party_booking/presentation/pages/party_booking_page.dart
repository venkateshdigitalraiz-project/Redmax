import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/party_colors.dart';
import '../../core/party_formatters.dart';
import '../../core/party_injector.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_booking_form_bloc.dart';
import '../party_navigator.dart';
import '../widgets/party_widgets.dart';
import 'party_booking_confirmed_page.dart';

String partyPaymentLabel(PartyPaymentMethod m) {
  switch (m) {
    case PartyPaymentMethod.upi:
      return 'UPI';
    case PartyPaymentMethod.card:
      return 'Credit / Debit Card';
    case PartyPaymentMethod.netBanking:
      return 'Net Banking';
  }
}

/// Screen 4: "Book Your Party" – 4-step flow driven by [PartyBookingFormBloc].
class PartyBookingPage extends StatelessWidget {
  const PartyBookingPage({super.key, required this.venue});
  final PartyVenueEntity venue;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartyInjector.I.bookingFormBloc(venue)
        ..add(const PartyBookingFormStarted()),
      child: const _BookingView(),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartyBookingFormBloc, PartyBookingFormState>(
      listenWhen: (p, c) =>
          (c.error != null && p.error != c.error) ||
          (p.status != c.status && c.status == PartyStatus.success),
      listener: (context, s) {
        if (s.status == PartyStatus.success && s.booking != null) {
          PartyNavigator.replace(
              context, PartyBookingConfirmedPage(booking: s.booking!));
        } else if (s.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s.error!)));
        }
      },
      builder: (context, s) {
        final bloc = context.read<PartyBookingFormBloc>();
        return PopScope(
          canPop: s.step == 0,
          onPopInvoked: (didPop) {
            if (!didPop) bloc.add(const PartyBookingBackPressed());
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PartyHeaderBar(
                  title: 'Book Your Party',
                  onBack: () => s.step == 0
                      ? Navigator.maybePop(context)
                      : bloc.add(const PartyBookingBackPressed()),
                ),
                PartyStepIndicator(current: s.step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(s.step),
                        child: _stepBody(context, s),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: s.status == PartyStatus.loading
                          ? null
                          : () => bloc.add(const PartyBookingNextPressed()),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C1CDD),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4C1CDD).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: s.status == PartyStatus.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.isLastStep
                                        ? 'Confirm Booking'
                                        : 'Next Step →',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepBody(BuildContext context, PartyBookingFormState s) {
    switch (s.step) {
      case 0:
        return _DateTimeStep(state: s);
      case 1:
        return _DetailsStep(state: s);
      case 2:
        return _PaymentStep(state: s);
      default:
        return _ConfirmStep(state: s);
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
      );
}

// ---------------------------------------------------------------- step 1
class _DateTimeStep extends StatelessWidget {
  const _DateTimeStep({required this.state});
  final PartyBookingFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PartyBookingFormBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Select Date'),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) bloc.add(PartyBookingDateChanged(picked));
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    PartyFormatters.date(state.date),
                    style: const TextStyle(
                      color: Color(0xFF140D43),
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF140D43),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _Label('Select Time'),
        if (state.slots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 3),
          )
        else
          Row(
            children: [
              for (final slot in state.slots)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => bloc.add(PartyBookingSlotSelected(slot)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: slot == state.slot
                              ? const Color(0xFF4C1CDD)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: slot == state.slot
                              ? null
                              : Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                          boxShadow: slot == state.slot
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4C1CDD)
                                        .withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: slot == state.slot
                                ? Colors.white
                                : const Color(0xFF140D43),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 22),
        const _Label('Number of Guests'),
        Center(
          child: Container(
            width: 310,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => bloc.add(const PartyBookingGuestsChanged(-10)),
                ),
                Expanded(
                  child: Text(
                    '${state.guests}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF140D43),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => bloc.add(const PartyBookingGuestsChanged(10)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Up to ${state.venue.capacity} guests at ${state.venue.name}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 52,
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: const Color(0xFF140D43)),
        ),
      );
}

// ---------------------------------------------------------------- step 2
class _DetailsStep extends StatefulWidget {
  const _DetailsStep({required this.state});
  final PartyBookingFormState state;

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  late final TextEditingController _name =
      TextEditingController(text: widget.state.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.state.phone);
  late final TextEditingController _notes =
      TextEditingController(text: widget.state.notes);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PartyBookingFormBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Your Details'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => bloc.add(PartyBookingNameChanged(v)),
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (v) => bloc.add(PartyBookingPhoneChanged(v)),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+91  ',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notes,
          maxLines: 3,
          onChanged: (v) => bloc.add(PartyBookingNotesChanged(v)),
          decoration: const InputDecoration(
            labelText: 'Special Requests (optional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- step 3
class _PaymentStep extends StatelessWidget {
  const _PaymentStep({required this.state});
  final PartyBookingFormState state;

  IconData _icon(PartyPaymentMethod m) {
    switch (m) {
      case PartyPaymentMethod.upi:
        return Icons.account_balance_wallet_rounded;
      case PartyPaymentMethod.card:
        return Icons.credit_card_rounded;
      case PartyPaymentMethod.netBanking:
        return Icons.account_balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PartyBookingFormBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Payment Summary'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PartyColors.tile,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _SummaryRow('Venue charges', PartyFormatters.rupee(state.totalAmount)),
              const SizedBox(height: 8),
              _SummaryRow('Pay now (20% advance)',
                  PartyFormatters.rupee(state.advanceAmount),
                  bold: true, color: PartyColors.primary),
              const SizedBox(height: 8),
              _SummaryRow(
                  'Balance at venue',
                  PartyFormatters.rupee(state.totalAmount - state.advanceAmount)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _Label('Payment Method'),
        for (final m in PartyPaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => bloc.add(PartyBookingPaymentSelected(m)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: state.payment == m
                      ? PartyColors.chip
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.payment == m
                        ? PartyColors.primary
                        : PartyColors.border,
                    width: state.payment == m ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_icon(m), color: PartyColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(partyPaymentLabel(m),
                          style: AppTypography.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Icon(
                      state.payment == m
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: state.payment == m
                          ? PartyColors.primary
                          : PartyColors.subtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: PartyColors.text,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(value,
              style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800, color: color ?? PartyColors.text)),
        ],
      );
}

// ---------------------------------------------------------------- step 4
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.state});
  final PartyBookingFormState state;

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['Venue', state.venue.name],
      ['Date', PartyFormatters.date(state.date)],
      ['Time', state.slot ?? '-'],
      ['Guests', '${state.guests}'],
      ['Name', state.name.trim()],
      ['Phone', '+91 ${state.phone}'],
      if (state.notes.trim().isNotEmpty) ['Requests', state.notes.trim()],
      [
        'Payment',
        state.payment == null ? '-' : partyPaymentLabel(state.payment!)
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Review & Confirm'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PartyColors.tile,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(rows[i][0],
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13.5)),
                    ),
                    Expanded(
                      child: Text(rows[i][1],
                          style: AppTypography.bodyLarge
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
                if (i != rows.length - 1) const SizedBox(height: 10),
              ],
              const Divider(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text('Pay now',
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text(PartyFormatters.rupee(state.advanceAmount),
                      style: AppTypography.titleLarge
                          .copyWith(color: PartyColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Your booking is confirmed instantly. The balance is payable at the venue.',
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5)),
      ],
    );
  }
}
