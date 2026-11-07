import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/repositories/search_booking_rider_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';
import '../bloc/search_booking_rider_bloc.dart';

/// Aliases to support exact user naming conventions
typedef searchBookingrider = SearchBookingRiderPage;
typedef SearchBookingRider = SearchBookingRiderPage;

/// Clean Architecture Search & Booking Rider Page
class SearchBookingRiderPage extends StatelessWidget {
  const SearchBookingRiderPage({super.key});

  /// Static helper to navigate cleanly from any context
  static Future<void> show(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchBookingRiderPage()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = SearchBookingRiderRepositoryImpl();

    return BlocProvider<SearchBookingRiderBloc>(
      create: (_) => SearchBookingRiderBloc(
        getBookings: GetRiderBookingsUseCase(repo),
        searchRides: SearchRiderRidesUseCase(repo),
        bookSeat: BookRiderSeatUseCase(repo),
        cancelBooking: CancelRiderBookingUseCase(repo),
      )..add(const SearchBookingRiderStarted()),
      child: const _SearchBookingRiderView(),
    );
  }
}

class _SearchBookingRiderView extends StatefulWidget {
  const _SearchBookingRiderView();

  @override
  State<_SearchBookingRiderView> createState() =>
      _SearchBookingRiderViewState();
}

class _SearchBookingRiderViewState extends State<_SearchBookingRiderView> {
  final TextEditingController _fromCtrl = TextEditingController(
    text: 'Hyderabad',
  );
  final TextEditingController _toCtrl = TextEditingController(
    text: 'Vijayawada',
  );
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 4));
  int _bookingSubTab = 0; // 0: Active, 1: Past

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF5D24F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5D24F7),
            onPrimary: Colors.white,
            onSurface: Color(0xFF140D43),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSearch(BuildContext context) {
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      _snack(context, 'Please enter pickup and dropoff points', isError: true);
      return;
    }
    context.read<SearchBookingRiderBloc>().add(
      SearchBookingRiderSearchRequested(
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
        date: _selectedDate,
      ),
    );
  }

  void _confirmCancelBooking(
    BuildContext context,
    RiderBookingEntity booking,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Cancel This Booking?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF140D43),
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your seat from ${booking.from} to ${booking.to}?',
          style: const TextStyle(color: Color(0xFF6B658C), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Booking',
              style: TextStyle(color: Color(0xFF6B658C)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<SearchBookingRiderBloc>().add(
        SearchBookingRiderCancelBookingRequested(booking.id),
      );
    }
  }

  void _showBookSeatDialog(BuildContext context, CarpoolRideEntity ride) {
    int selectedSeats = 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD6FE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Book Seat with ${ride.driverName}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ride.from} → ${ride.to}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D24F7),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFEDE8FF)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Seats',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF140D43),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Color(0xFF5D24F7),
                        ),
                        onPressed: selectedSeats > 1
                            ? () => setModalState(() => selectedSeats--)
                            : null,
                      ),
                      Text(
                        '$selectedSeats',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Color(0xFF5D24F7),
                        ),
                        onPressed: selectedSeats < ride.seats
                            ? () => setModalState(() => selectedSeats++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Fare',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B658C)),
                  ),
                  Text(
                    CarpoolFormatters.rupee(ride.pricePerSeat * selectedSeats),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5D24F7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D24F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<SearchBookingRiderBloc>().add(
                      SearchBookingRiderBookSeatRequested(
                        ride: ride,
                        seats: selectedSeats,
                      ),
                    );
                  },
                  child: const Text(
                    'Confirm & Book Seat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Color(0xFFFAFAFF),
              Colors.white,
            ],
            stops: [0.0, 0.25, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<SearchBookingRiderBloc, SearchBookingRiderState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, s) => _snack(context, s.message!),
            builder: (context, s) {
              return Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF140D43),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Rider Bookings & Search',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Search rides & manage your passenger bookings',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Segmented Master Tabs ("My Bookings" vs "Search Rides")
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE6FC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          // Tab 0: My Bookings
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context
                                  .read<SearchBookingRiderBloc>()
                                  .add(const SearchBookingRiderTabChanged(0)),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: s.tabIndex == 0
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF5D24F7),
                                            Color(0xFF300AB3),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: s.tabIndex == 0
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF4C1CDD,
                                            ).withOpacity(0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_rounded,
                                      size: 15,
                                      color: s.tabIndex == 0
                                          ? Colors.white
                                          : const Color(0xFF5D24F7),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'My Bookings',
                                      style: TextStyle(
                                        color: s.tabIndex == 0
                                            ? Colors.white
                                            : const Color(0xFF140D43),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (s.activeBookingsCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: s.tabIndex == 0
                                              ? Colors.white.withOpacity(0.25)
                                              : const Color(0xFFDDD6FE),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${s.activeBookingsCount}',
                                          style: TextStyle(
                                            color: s.tabIndex == 0
                                                ? Colors.white
                                                : const Color(0xFF5D24F7),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Tab 1: Search Rides
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context
                                  .read<SearchBookingRiderBloc>()
                                  .add(const SearchBookingRiderTabChanged(1)),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: s.tabIndex == 1
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF5D24F7),
                                            Color(0xFF300AB3),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: s.tabIndex == 1
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF4C1CDD,
                                            ).withOpacity(0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: s.tabIndex == 1
                                          ? Colors.white
                                          : const Color(0xFF5D24F7),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Find Rides',
                                      style: TextStyle(
                                        color: s.tabIndex == 1
                                            ? Colors.white
                                            : const Color(0xFF140D43),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child:
                        s.status == CarpoolStatus.loading &&
                            s.bookings.isEmpty &&
                            s.searchResults.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D24F7),
                            ),
                          )
                        : s.tabIndex == 0
                        ? _buildMyBookingsTab(context, s)
                        : _buildSearchRidesTab(context, s),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab(
    BuildContext context,
    SearchBookingRiderState state,
  ) {
    final list = _bookingSubTab == 0
        ? state.activeBookings
        : state.pastBookings;

    return Column(
      children: [
        // Sub-filter pill row (Active vs Past)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _subFilterChip('Active (${state.activeBookingsCount})', 0),
              const SizedBox(width: 10),
              _subFilterChip('Past (${state.pastBookingsCount})', 1),
            ],
          ),
        ),

        // Bookings List or Empty State
        Expanded(
          child: list.isEmpty
              ? _buildEmptyBookingsState(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final booking = list[i];
                    return _RiderBookingCard(
                      booking: booking,
                      onCancel: () => _confirmCancelBooking(context, booking),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _subFilterChip(String label, int index) {
    final isSelected = _bookingSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _bookingSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D24F7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5D24F7)
                : const Color(0xFFEDE8FF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B658C),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBookingsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: Color(0xFF5D24F7),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _bookingSubTab == 0
                  ? 'No Active Rider Bookings'
                  : 'No Past Bookings',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Looking to travel? Switch to Find Rides to search and book seats on available routes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D24F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
              ),
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Search Available Rides',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => context.read<SearchBookingRiderBloc>().add(
                const SearchBookingRiderTabChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRidesTab(
    BuildContext context,
    SearchBookingRiderState state,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Route Search Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4C1CDD).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Origin Input
              TextField(
                controller: _fromCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  hintText: 'Enter pickup city/location',
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Color(0xFFEDE8FF), height: 1),
              // Destination Input
              TextField(
                controller: _toCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  hintText: 'Enter dropoff city/location',
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Color(0xFFEDE8FF), height: 1),
              const SizedBox(height: 12),
              // Date picker button & Search Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEDE8FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF5D24F7),
                      ),
                      label: Text(
                        CarpoolFormatters.date(_selectedDate),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D24F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _onSearch(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Available Rides Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Rides (${state.searchResults.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            const Text(
              'Instant Booking',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search Results List
        if (state.searchResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No rides found for this route. Try adjusting your search points.',
                style: TextStyle(color: Color(0xFF6B658C), fontSize: 13),
              ),
            ),
          )
        else
          ...state.searchResults.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SearchResultCard(
                ride: ride,
                onBook: () => _showBookSeatDialog(context, ride),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card representing a Rider's Booked Trip
class _RiderBookingCard extends StatelessWidget {
  final RiderBookingEntity booking;
  final VoidCallback onCancel;

  const _RiderBookingCard({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = booking.status == RiderBookingStatus.confirmed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge, OTP code, Booking ID
          Row(
            children: [
              _statusBadge(booking.status),
              const SizedBox(width: 8),
              if (booking.otpCode != null && isConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'OTP: ${booking.otpCode}',
                    style: const TextStyle(
                      color: Color(0xFF5D24F7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '#${booking.id}',
                style: const TextStyle(
                  color: Color(0xFF8B85A8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date & Time Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: Color(0xFF5D24F7),
                ),
                const SizedBox(width: 6),
                Text(
                  CarpoolFormatters.headline(booking.departure),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF140D43),
                  ),
                ),
                const Spacer(),
                Text(
                  '${booking.seatsBooked} seat(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Route Timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 3),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 26,
                    color: const Color(0xFFDDD6FE),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.from,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      booking.to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF140D43),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Driver & Vehicle row with Price
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEDE8FF),
                  child: Text(
                    booking.driverName.isNotEmpty ? booking.driverName[0] : 'D',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5D24F7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.driverName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      Text(
                        '${booking.vehicle} • ${booking.vehicleNumber ?? ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CarpoolFormatters.rupee(booking.totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ],
            ),
          ),

          if (isConfirmed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(RiderBookingStatus status) {
    Color bg;
    Color fg;
    String text;
    switch (status) {
      case RiderBookingStatus.confirmed:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        text = '● Confirmed';
        break;
      case RiderBookingStatus.completed:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        text = '✔ Completed';
        break;
      case RiderBookingStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = '✕ Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Search Result Card for Riders
class _SearchResultCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final VoidCallback onBook;

  const _SearchResultCard({required this.ride, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info & Price
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEDE8FF),
                child: Text(
                  ride.driverName.isNotEmpty ? ride.driverName[0] : 'D',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ride.driverName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFFB800),
                        ),
                        Text(
                          '${ride.driverRating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ride.vehicle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B658C),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CarpoolFormatters.rupee(ride.pricePerSeat),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5D24F7),
                    ),
                  ),
                  const Text(
                    'per seat',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF8B85A8)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Departure time & Seats left
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF5D24F7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CarpoolFormatters.shortDateTime(ride.departure),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ride.seats} seats available',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D24F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 0,
                ),
                onPressed: onBook,
                child: const Text(
                  'Book Seat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
