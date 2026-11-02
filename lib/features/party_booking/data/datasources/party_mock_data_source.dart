import '../../domain/entities/party_entities.dart';
import '../models/party_models.dart';
import 'party_remote_data_source.dart';

/// In-memory implementation so the module runs without a backend.
/// Swap for an API-backed [PartyRemoteDataSource] in `PartyInjector`.
/// Fill `imageUrls` / `imageUrl` with real photo URLs when you have them.
class PartyMockDataSource implements PartyRemoteDataSource {
  PartyMockDataSource() {
    final now = DateTime.now();
    DateTime day(int offset) =>
        DateTime(now.year, now.month, now.day + offset);

    _bookings = [
      PartyBookingModel(
        id: 'b1', venue: _venues[0], date: day(13), timeSlot: '1:00 PM',
        guests: 100, status: PartyBookingStatus.confirmed,
        guestName: 'Venkatesh', phone: '9876543210', notes: '',
        paymentMethod: PartyPaymentMethod.upi,
        totalAmount: _venues[0].priceFrom,
        advanceAmount: (_venues[0].priceFrom * .2).round(),
      ),
      PartyBookingModel(
        id: 'b2', venue: _venues[1], date: day(28), timeSlot: '7:00 PM',
        guests: 50, status: PartyBookingStatus.pending,
        guestName: 'Venkatesh', phone: '9876543210', notes: '',
        paymentMethod: PartyPaymentMethod.card,
        totalAmount: _venues[1].priceFrom,
        advanceAmount: (_venues[1].priceFrom * .2).round(),
      ),
      PartyBookingModel(
        id: 'b3', venue: _venues[2], date: day(-20), timeSlot: '5:00 PM',
        guests: 60, status: PartyBookingStatus.completed,
        guestName: 'Venkatesh', phone: '9876543210', notes: '',
        paymentMethod: PartyPaymentMethod.upi,
        totalAmount: _venues[2].priceFrom,
        advanceAmount: (_venues[2].priceFrom * .2).round(),
      ),
    ];
  }

  static const _slots = ['10:00 AM', '1:00 PM', '5:00 PM', '8:00 PM'];

  static const _categories = [
    PartyCategoryModel(id: 'birthday', name: 'Birthday Parties', shortName: 'Birthday'),
    PartyCategoryModel(id: 'wedding', name: 'Wedding Functions', shortName: 'Wedding'),
    PartyCategoryModel(id: 'corporate', name: 'Corporate Events', shortName: 'Corporate'),
    PartyCategoryModel(id: 'celebrations', name: 'Celebrations', shortName: 'Celebrations'),
    PartyCategoryModel(id: 'baby_shower', name: 'Baby Shower', shortName: 'Baby Shower'),
    PartyCategoryModel(id: 'get_together', name: 'Get Together', shortName: 'Get Together'),
  ];

  static const _venues = <PartyVenueModel>[
    PartyVenueModel(
      id: 'v1', name: 'Royal Garden Banquet', location: 'Jubilee Hills, Hyderabad',
      rating: 4.6, reviewCount: 1200, priceFrom: 25000, capacity: 500,
      hasAc: true, hasParking: true, hasCatering: true,
      description:
          'A premium banquet hall for your special occasions. Spacious, elegant and well equipped for all celebrations. Enjoy crystal chandeliers, a dedicated bridal suite, valet parking and an in-house catering team that can handle everything from intimate dinners to grand receptions.',
      categoryIds: ['birthday', 'wedding', 'celebrations', 'get_together'],
      imageUrls: [
        'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?fit=crop&w=800&q=80',
      ],
      imageCount: 5,
    ),
    PartyVenueModel(
      id: 'v2', name: 'The Grand Celebrations', location: 'Banjara Hills, Hyderabad',
      rating: 4.7, reviewCount: 860, priceFrom: 40000, capacity: 300,
      hasAc: true, hasParking: true, hasCatering: true,
      description:
          'An elegant multi-level hall with a stage, LED walls and a lounge area. Perfect for weddings, receptions and corporate galas with a flexible layout and premium sound system.',
      categoryIds: ['wedding', 'corporate', 'celebrations'],
      imageUrls: [
        'https://images.unsplash.com/photo-1545232979-fbf68fe9b10d?fit=crop&w=800&q=80',
      ],
      imageCount: 4,
    ),
    PartyVenueModel(
      id: 'v3', name: 'Skyline Terrace', location: 'Gachibowli, Hyderabad',
      rating: 4.4, reviewCount: 540, priceFrom: 18000, capacity: 150,
      hasAc: false, hasParking: true, hasCatering: true,
      description:
          'An open-air rooftop with a skyline view, string lights and a built-in bar counter. Great for birthday parties and relaxed get-togethers.',
      categoryIds: ['birthday', 'get_together', 'baby_shower'],
      imageUrls: [
        'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?fit=crop&w=800&q=80',
      ],
      imageCount: 3,
    ),
    PartyVenueModel(
      id: 'v4', name: 'Blossom Hall', location: 'Madhapur, Hyderabad',
      rating: 4.5, reviewCount: 390, priceFrom: 15000, capacity: 120,
      hasAc: true, hasParking: false, hasCatering: true,
      description:
          'A cosy, flower-themed hall that is ideal for baby showers, birthdays and family functions. Includes decoration support and a children\'s play corner.',
      categoryIds: ['baby_shower', 'birthday', 'get_together'],
    ),
    PartyVenueModel(
      id: 'v5', name: 'Orchid Convention', location: 'Hitech City, Hyderabad',
      rating: 4.8, reviewCount: 2100, priceFrom: 60000, capacity: 800,
      hasAc: true, hasParking: true, hasCatering: true,
      description:
          'A large convention centre with multiple halls, a grand lawn and ample parking. Built for big weddings, conferences and corporate events.',
      categoryIds: ['corporate', 'wedding'],
    ),
  ];

  late final List<PartyBookingModel> _bookings;
  final Set<String> _favoriteIds = {};
  int _counter = 100;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  PartyVenueModel _byId(String id) =>
      _venues.firstWhere((v) => v.id == id,
          orElse: () => throw const PartyFailure('Venue not found.'));

  @override
  Future<List<PartyCategoryModel>> fetchCategories() async {
    await _latency();
    return _categories;
  }

  @override
  Future<List<PartyVenueModel>> fetchPopularVenues() async {
    await _latency();
    final list = [..._venues]..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return list.take(4).toList();
  }

  @override
  Future<List<PartyVenueModel>> searchVenues(PartySearchVenuesParams p) async {
    await _latency();
    final q = p.query.trim().toLowerCase();
    return _venues.where((v) {
      final inCategory = p.categoryId == null || v.categoryIds.contains(p.categoryId);
      final matches = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q);
      return inCategory && matches;
    }).toList();
  }

  @override
  Future<PartyVenueModel> fetchVenue(String venueId) async {
    await _latency();
    return _byId(venueId);
  }

  @override
  Future<List<String>> fetchTimeSlots(PartyTimeSlotsParams params) async {
    await _latency();
    return _slots;
  }

  @override
  Future<List<PartyVenueModel>> fetchFavorites() async {
    await _latency();
    return _venues.where((v) => _favoriteIds.contains(v.id)).toList();
  }

  @override
  Future<List<PartyVenueModel>> toggleFavorite(String venueId) async {
    _favoriteIds.contains(venueId)
        ? _favoriteIds.remove(venueId)
        : _favoriteIds.add(venueId);
    return _venues.where((v) => _favoriteIds.contains(v.id)).toList();
  }

  @override
  Future<PartyBookingModel> createBooking(PartyCreateBookingParams p) async {
    await _latency();
    final venue = _byId(p.venueId);
    if (p.guests > venue.capacity) {
      throw PartyFailure('${venue.name} hosts up to ${venue.capacity} guests.');
    }
    final booking = PartyBookingModel(
      id: 'b${_counter++}',
      venue: venue,
      date: p.date,
      timeSlot: p.timeSlot,
      guests: p.guests,
      status: PartyBookingStatus.confirmed,
      guestName: p.guestName.trim(),
      phone: p.phone,
      notes: p.notes.trim(),
      paymentMethod: p.paymentMethod,
      totalAmount: venue.priceFrom,
      advanceAmount: (venue.priceFrom * .2).round(),
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<List<PartyBookingModel>> fetchBookings() async {
    await _latency();
    return [..._bookings]..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _latency();
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i != -1) {
      _bookings[i] = _bookings[i].copyWith(status: PartyBookingStatus.cancelled);
    }
  }
}
