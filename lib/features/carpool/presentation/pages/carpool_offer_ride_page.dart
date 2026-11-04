import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_home_bloc.dart';
import '../bloc/carpool_nav_cubit.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../widgets/carpool_route_selector_card.dart';

/// Screen "Offer a Ride" matching the exact design screenshot:
/// 1. Top bar with clean back button, "Offer a Ride" title, and tune icon.
/// 2. Framed car illustration with natural orientation and curved bottom border.
/// 3. "Carpool" / "Courier" segmented pill switch.
/// 4. White card with From, To (with circular Swap button), Date, and Time.
/// 5. "Seats Available" row with lavender pill stepper.
/// 6. "Ride Type" section with "Normal" & "Premium" pills.
/// 7. "Post Ride →" royal purple gradient button.
class CarpoolOfferRidePage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;

  const CarpoolOfferRidePage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _OfferRideView());
    }

    try {
      final existing = context.read<CarpoolOfferRideBloc>();
      return BlocProvider.value(value: existing, child: const _OfferRideView());
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      final publishRideUseCase = CarpoolPublishRideUseCase(repository);

      return BlocProvider(
        create: (_) => CarpoolOfferRideBloc(publishRide: publishRideUseCase),
        child: const _OfferRideView(),
      );
    }
  }
}

Future<String?> carpoolAskText(
  BuildContext context,
  String title,
  String initial,
) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF140D43),
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Enter city or place',
          filled: true,
          fillColor: const Color(0xFFF7F5FE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3815D8), width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF6B658C)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3815D8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _OfferRideView extends StatelessWidget {
  const _OfferRideView();

  Future<void> _pickDate(BuildContext context, CarpoolOfferRideState s) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: s.departure.isBefore(now) ? now : s.departure,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<CarpoolOfferRideBloc>().add(CarpoolOfferDateChanged(picked));
    }
  }

  Future<void> _pickTime(BuildContext context, CarpoolOfferRideState s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: s.departure.hour,
        minute: s.departure.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<CarpoolOfferRideBloc>().add(
        CarpoolOfferTimeChanged(picked.hour, picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBE6FC), Color(0xFFF7F5FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.40, 1.0],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<CarpoolOfferRideBloc, CarpoolOfferRideState>(
            builder: (context, s) {
              final bloc = context.read<CarpoolOfferRideBloc>();

              return Column(
                children: [
                  // 1. Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Offer a Ride',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF140D43),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 28),
                      children: [
                        // Car Illustration with Organic Curved Bottom Border
                        const _CarIllustrationHeader(),

                        const SizedBox(height: 12),

                        // Carpool / Courier Toggle Pill
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 20),
                        //   child: Container(
                        //     height: 48,
                        //     padding: const EdgeInsets.all(3.5),
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       borderRadius: BorderRadius.circular(24),
                        //       border: Border.all(
                        //         color: const Color(0xFFEDE8FF),
                        //         width: 1.2,
                        //       ),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: const Color(
                        //             0xFF5B3BF5,
                        //           ).withOpacity(0.06),
                        //           blurRadius: 12,
                        //           offset: const Offset(0, 4),
                        //         ),
                        //       ],
                        //     ),
                        //     child: Row(
                        //       children: [
                        //         // Carpool Tab (Active)
                        //         Expanded(
                        //           child: Container(
                        //             height: double.infinity,
                        //             decoration: BoxDecoration(
                        //               gradient: const LinearGradient(
                        //                 colors: [
                        //                   Color(0xFF5428E8),
                        //                   Color(0xFF240DA2),
                        //                 ],
                        //               ),
                        //               borderRadius: BorderRadius.circular(20),
                        //               boxShadow: [
                        //                 BoxShadow(
                        //                   color: const Color(
                        //                     0xFF4C1CDD,
                        //                   ).withOpacity(0.35),
                        //                   blurRadius: 8,
                        //                   offset: const Offset(0, 3),
                        //                 ),
                        //               ],
                        //             ),
                        //             alignment: Alignment.center,
                        //             child: const Text(
                        //               'Carpool',
                        //               style: TextStyle(
                        //                 color: Colors.white,
                        //                 fontWeight: FontWeight.w700,
                        //                 fontSize: 15,
                        //               ),
                        //             ),
                        //           ),
                        //         ),

                        //         // Courier Tab (Inactive)
                        //         Expanded(
                        //           child: GestureDetector(
                        //             onTap: () {
                        //               ScaffoldMessenger.of(
                        //                 context,
                        //               ).showSnackBar(
                        //                 const SnackBar(
                        //                   content: Text(
                        //                     'Courier is coming soon',
                        //                   ),
                        //                   duration: Duration(seconds: 1),
                        //                 ),
                        //               );
                        //             },
                        //             behavior: HitTestBehavior.opaque,
                        //             child: Container(
                        //               height: double.infinity,
                        //               alignment: Alignment.center,
                        //               child: const Text(
                        //                 'Courier',
                        //                 style: TextStyle(
                        //                   color: Color(0xFF140D43),
                        //                   fontWeight: FontWeight.w700,
                        //                   fontSize: 15,
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 16),

                        // Route & Details Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5B3BF5,
                                  ).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Column(
                              children: [
                                // Shared From/To Route Selector (with Rapido Places Autocomplete & Swap)
                                CarpoolFromToSelector(
                                  from: s.from,
                                  to: s.to,
                                  onFromChanged: (v) =>
                                      bloc.add(CarpoolOfferFromChanged(v)),
                                  onToChanged: (v) =>
                                      bloc.add(CarpoolOfferToChanged(v)),
                                  onFromLocationChanged: (name, lat, lng) =>
                                      bloc.add(
                                        CarpoolOfferFromChanged(
                                          name,
                                          lat: lat,
                                          lng: lng,
                                        ),
                                      ),
                                  onToLocationChanged: (name, lat, lng) =>
                                      bloc.add(
                                        CarpoolOfferToChanged(
                                          name,
                                          lat: lat,
                                          lng: lng,
                                        ),
                                      ),
                                  onSwap: () =>
                                      bloc.add(const CarpoolOfferSwapPressed()),
                                ),

                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF1EEFC),
                                ),

                                // "Date" Row
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _pickDate(context, s),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          color: Color(0xFF1D1464),
                                          size: 26,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Date',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF6B658C),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                CarpoolFormatters.date(
                                                  s.departure,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF140D43),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF9E9AB8),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF1EEFC),
                                ),

                                // "Time" Row
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _pickTime(context, s),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: Color(0xFF1D1464),
                                          size: 26,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Time',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF6B658C),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                CarpoolFormatters.time(
                                                  s.departure,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF140D43),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF9E9AB8),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Seats Available Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              const Text(
                                'Seats Available',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE8FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => bloc.add(
                                        const CarpoolOfferSeatsChanged(-1),
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        child: const Icon(
                                          Icons.remove_rounded,
                                          size: 18,
                                          color: Color(0xFF3815D8),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '${s.seats}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF140D43),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => bloc.add(
                                        const CarpoolOfferSeatsChanged(1),
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: Color(0xFF3815D8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Ride Type Section
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 22),
                        //   child: const Text(
                        //     'Ride Type',
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.w800,
                        //       fontSize: 15,
                        //       color: Color(0xFF140D43),
                        //     ),
                        //   ),
                        // ),

                        // const SizedBox(height: 8),

                        // // Ride Type Pills (Normal / Premium)
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 20),
                        //   child: Row(
                        //     children: [
                        //       // Normal Pill
                        //       Expanded(
                        //         child: GestureDetector(
                        //           onTap: () => bloc.add(
                        //             const CarpoolOfferRideTypeChanged(
                        //               CarpoolRideType.normal,
                        //             ),
                        //           ),
                        //           behavior: HitTestBehavior.opaque,
                        //           child: Container(
                        //             height: 46,
                        //             decoration: BoxDecoration(
                        //               gradient:
                        //                   s.rideType == CarpoolRideType.normal
                        //                   ? const LinearGradient(
                        //                       colors: [
                        //                         Color(0xFF6F35FF),
                        //                         Color(0xFF3815D8),
                        //                       ],
                        //                     )
                        //                   : null,
                        //               color:
                        //                   s.rideType == CarpoolRideType.normal
                        //                   ? null
                        //                   : const Color(0xFFEDE8FF),
                        //               borderRadius: BorderRadius.circular(23),
                        //               boxShadow:
                        //                   s.rideType == CarpoolRideType.normal
                        //                   ? [
                        //                       BoxShadow(
                        //                         color: const Color(
                        //                           0xFF4C1CDD,
                        //                         ).withOpacity(0.35),
                        //                         blurRadius: 10,
                        //                         offset: const Offset(0, 4),
                        //                       ),
                        //                     ]
                        //                   : null,
                        //             ),
                        //             alignment: Alignment.center,
                        //             child: Text(
                        //               'Normal',
                        //               style: TextStyle(
                        //                 color:
                        //                     s.rideType == CarpoolRideType.normal
                        //                     ? Colors.white
                        //                     : const Color(0xFF140D43),
                        //                 fontWeight: FontWeight.w700,
                        //                 fontSize: 15,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ),

                        //       const SizedBox(width: 14),

                        //       // Premium Pill
                        //       Expanded(
                        //         child: GestureDetector(
                        //           onTap: () => bloc.add(
                        //             const CarpoolOfferRideTypeChanged(
                        //               CarpoolRideType.premium,
                        //             ),
                        //           ),
                        //           behavior: HitTestBehavior.opaque,
                        //           child: Container(
                        //             height: 46,
                        //             decoration: BoxDecoration(
                        //               gradient:
                        //                   s.rideType == CarpoolRideType.premium
                        //                   ? const LinearGradient(
                        //                       colors: [
                        //                         Color(0xFF6F35FF),
                        //                         Color(0xFF3815D8),
                        //                       ],
                        //                     )
                        //                   : null,
                        //               color:
                        //                   s.rideType == CarpoolRideType.premium
                        //                   ? null
                        //                   : const Color(0xFFEDE8FF),
                        //               borderRadius: BorderRadius.circular(23),
                        //               boxShadow:
                        //                   s.rideType == CarpoolRideType.premium
                        //                   ? [
                        //                       BoxShadow(
                        //                         color: const Color(
                        //                           0xFF4C1CDD,
                        //                         ).withOpacity(0.35),
                        //                         blurRadius: 10,
                        //                         offset: const Offset(0, 4),
                        //                       ),
                        //                     ]
                        //                   : null,
                        //             ),
                        //             alignment: Alignment.center,
                        //             child: Text(
                        //               'Premium',
                        //               style: TextStyle(
                        //                 color:
                        //                     s.rideType ==
                        //                         CarpoolRideType.premium
                        //                     ? Colors.white
                        //                     : const Color(0xFF140D43),
                        //                 fontWeight: FontWeight.w700,
                        //                 fontSize: 15,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        const SizedBox(height: 22),

                        // Post Ride Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5D24F7), Color(0xFF300AB3)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4C1CDD,
                                  ).withOpacity(0.38),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(27),
                                onTap: () {
                                  if (!s.isValid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter two different locations to continue',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // 1. Calculate distance and price (₹10/km)
                                  final dist =
                                      CarpoolDistanceCalculator.calculateDistanceKm(
                                        s.from,
                                        s.to,
                                      );
                                  final totalFare = dist * 10;
                                  final pricePerSeat =
                                      (totalFare / (s.seats > 0 ? s.seats : 1))
                                          .round();

                                  // 2. Temporarily save ride and popular route in memory datasource
                                  final mockDs = CarpoolMockDataSource();
                                  mockDs.addPopularRoute(
                                    s.from,
                                    s.to,
                                    pricePerSeat,
                                    fromLat: s.fromLat,
                                    fromLng: s.fromLng,
                                    toLat: s.toLat,
                                    toLng: s.toLng,
                                  );
                                  mockDs.publishRide(
                                    CarpoolPublishRideParams(
                                      from: s.from,
                                      to: s.to,
                                      departure: s.departure,
                                      seats: s.seats,
                                      //    pricePerSeat: pricePerSeat,
                                      rideType: s.rideType,
                                    ),
                                  );

                                  // 3. Immediately update CarpoolHomeBloc so Popular Routes on Home page updates
                                  try {
                                    context.read<CarpoolHomeBloc>().add(
                                      CarpoolHomeRouteAdded(
                                        from: s.from,
                                        to: s.to,
                                        price: pricePerSeat,
                                        fromLat: s.fromLat,
                                        fromLng: s.fromLng,
                                        toLat: s.toLat,
                                        toLng: s.toLng,
                                      ),
                                    );
                                  } catch (_) {}

                                  // 4. Switch to Home tab (index 0)
                                  try {
                                    context.read<CarpoolNavCubit>().select(0);
                                  } catch (_) {}

                                  // 5. Close current page and return to Home page
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }

                                  // 6. Show confirmation message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF140D43),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF00E676),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Ride posted: ${s.from} → ${s.to} (₹$pricePerSeat). Added to Popular Routes!',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Post Ride',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Car illustration header with rounded card shape, border radius, and elevation
class _CarIllustrationHeader extends StatelessWidget {
  final bool showPin;
  const _CarIllustrationHeader() : showPin = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 40; // 20px padding on each side
    final bannerHeight = (cardWidth * (358 / 538)).clamp(185.0, 225.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Container(
        height: bannerHeight,
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDE8FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B3BF5).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            children: [
              // Car Illustration Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/rider_image.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEBE6FC),
                      child: const Center(
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 64,
                          color: Color(0xFF5B3BF5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Decorative Top-Right Location Pin Badge
              if (showPin)
                Positioned(
                  top: 14,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C22E8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4C22E8).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
