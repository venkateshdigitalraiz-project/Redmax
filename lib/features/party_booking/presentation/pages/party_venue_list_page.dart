import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_formatters.dart';
import '../../core/party_injector.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_venue_list_bloc.dart';
import '../party_navigator.dart';
import 'party_venue_detail_page.dart';

/// Venues for one category (or all popular venues when [categoryId] is null).
/// Features a modern, polished App Bar with circular action buttons,
/// segmented filter pills, location tag, and luxury venue cards.
class PartyVenueListPage extends StatefulWidget {
  final String title;
  final String? categoryId;

  const PartyVenueListPage({super.key, required this.title, this.categoryId});

  @override
  State<PartyVenueListPage> createState() => _PartyVenueListPageState();
}

class _PartyVenueListPageState extends State<PartyVenueListPage> {
  int _selectedFilterIndex = 0;
  final List<String> _filterLabels = const [
    'All',
    'Top Rated',
    'Budget',
    'Luxury',
  ];

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Filter & Sort Venues',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF3F0FD)),
            const SizedBox(height: 10),
            _filterOption(ctx, 'Price: Low to High', 2),
            _filterOption(ctx, 'Price: High to Low (Luxury)', 3),
            _filterOption(ctx, 'Rating: 4.5+ Stars', 1),
            _filterOption(ctx, 'All Venues', 0),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(BuildContext ctx, String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF4C1CDD)
                : const Color(0xFF140D43),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4C1CDD))
            : null,
        onTap: () {
          setState(() => _selectedFilterIndex = index);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  List<PartyVenueEntity> _applyFilter(List<PartyVenueEntity> venues) {
    final list = [...venues];
    switch (_selectedFilterIndex) {
      case 1: // Top Rated
        return list.where((v) => v.rating >= 4.5).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case 2: // Budget
        return list..sort((a, b) => a.priceFrom.compareTo(b.priceFrom));
      case 3: // Luxury
        return list..sort((a, b) => b.priceFrom.compareTo(a.priceFrom));
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PartyInjector.I.venueListBloc()
            ..add(PartyVenueListStarted(widget.categoryId)),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEDE8FF), Color(0xFFF7F5FE), Colors.white],
                stops: [0.0, 0.25, 0.60],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. Sleek Modern App Bar (Back Arrow, Title, Tune Filter Icon)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    child: Row(
                      children: [
                        // Circular Elevated Back Button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5B3BF5,
                                  ).withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 22,
                            ),
                          ),
                        ),

                        // Title
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),

                        // Circular Elevated Filter/Tune Button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showFilterSheet(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5B3BF5,
                                  ).withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF140D43),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Segmented Filter Pills Row
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterLabels.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final isSelected = _selectedFilterIndex == idx;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _selectedFilterIndex = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6F35FF),
                                        Color(0xFF3309B8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : const Color(0xFFEBE6FC),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: isSelected
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
                            child: Text(
                              _filterLabels[idx],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF140D43),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Venues Content / List
                  Expanded(
                    child: BlocBuilder<PartyVenueListBloc, PartyVenueListState>(
                      builder: (context, state) {
                        if (state.status == PartyStatus.loading ||
                            state.status == PartyStatus.initial) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4C1CDD),
                            ),
                          );
                        }

                        final filteredVenues = _applyFilter(state.venues);

                        if (filteredVenues.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                'No venues match this filter.\nTry another option.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6B658C),
                                  fontSize: 14.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          children: [
                            // Header: Venue Count + Location Indicator
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 2,
                                right: 2,
                                bottom: 12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${filteredVenues.length} Venues found',
                                    style: const TextStyle(
                                      color: Color(0xFF6B658C),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF4C1CDD),
                                        size: 15,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Hyderabad',
                                        style: TextStyle(
                                          color: Color(0xFF4C1CDD),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Venue Cards
                            for (final v in filteredVenues)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _VenueCard(
                                  venue: v,
                                  onTap: () => PartyNavigator.push(
                                    context,
                                    PartyVenueDetailPage(venueId: v.id),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Venue Card matching the luxurious banquet card styling
class _VenueCard extends StatelessWidget {
  final PartyVenueEntity venue;
  final VoidCallback onTap;

  const _VenueCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoUrl = venue.coverImage.isNotEmpty
        ? venue.coverImage
        : 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?fit=crop&w=800&q=80';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B3BF5).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Venue Cover Photo with Floating Heart Button
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    photoUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: const Color(0xFFEBE6FC),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Color(0xFF4C1CDD),
                        size: 48,
                      ),
                    ),
                  ),

                  // Amenities Badges on bottom-left of photo
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${venue.capacity} Guests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (venue.hasAc) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '• AC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Top-Right Favorite Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: BlocBuilder<PartyFavoritesBloc, PartyFavoritesState>(
                      builder: (context, favState) {
                        final isFav = favState.isFavorite(venue.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.read<PartyFavoritesBloc>().add(
                            PartyFavoriteToggled(venue.id),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 1.5),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: Colors.black.withOpacity(0.35),
                                    size: 26,
                                  ),
                                ),
                                Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? const Color(0xFFFF4B6E)
                                      : Colors.white,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Venue Name & Price
            Row(
              children: [
                Expanded(
                  child: Text(
                    venue.name,
                    style: const TextStyle(
                      color: Color(0xFF140D43),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${PartyFormatters.rupee(venue.priceFrom)} onwards',
                  style: const TextStyle(
                    color: Color(0xFF140D43),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // 3. Location subtitle
            Text(
              venue.location,
              style: const TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 6),

            // 4. Rating & Reviews
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB800),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  venue.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF140D43),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  ' (${PartyFormatters.reviews(venue.reviewCount)})',
                  style: const TextStyle(
                    color: Color(0xFF6B658C),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
