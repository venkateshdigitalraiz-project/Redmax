import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/party_formatters.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_home_bloc.dart';
import '../party_navigator.dart';
import '../widgets/party_painters.dart';
import 'party_category_page.dart';
import 'party_venue_detail_page.dart';
import 'party_venue_list_page.dart';

/// PartyHomePage - Matches exact design specifications from screenshot:
/// 1. Hero Banner:
///    - Top bar: Location ("📍 Hyderabad ⌵") and notification bell.
///    - Atmospheric night celebration crowd image with stage lights & purple gradient overlay.
///    - Heading: "Make Your\nParty Special".
///    - Subtitle: "Book the Perfect Venue\nfor Every Celebration".
///    - Button: "Explore Venues →" white pill button.
///    - Organic sea-wave bottom scoop curve.
/// 2. Category Cards (4 items):
///    - Birthday (3D pink frosted cake with 3 candles)
///    - Wedding (3D golden interlocking rings with diamond)
///    - Corporate (3D clinking champagne celebration glasses)
///    - Others (3D golden-amber star)
/// 3. Popular Venues Section:
///    - Header: "Popular Venues" and "See All →".
///    - Card: High-res banquet hall photo, top-right white heart icon,
///      "Royal Garden Banquet", "₹25,000 onwards", and "★ 4.6 (1.2k reviews)".
/// 4. Fit screen without overflow on any mobile screen.
class PartyHomePage extends StatelessWidget {
  const PartyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<PartyHomeBloc, PartyHomeState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Hero Header Banner with Night Party Crowd & Organic Bottom Scoop
                const _PartyHeroBanner(),

                const SizedBox(height: 16),

                // 2. Four Quick Category Cards: Birthday, Wedding, Corporate, Others
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _CategoryPillsRow(),
                ),

                const SizedBox(height: 22),

                // 3. Section Header: "Popular Venues" & "See All →"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Popular Venues',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => PartyNavigator.push(
                          context,
                          const PartyVenueListPage(title: 'Popular Venues'),
                        ),
                        child: const Text(
                          'See All →',
                          style: TextStyle(
                            color: Color(0xFF4C1CDD),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Popular Venue Cards
                if (state.status == PartyStatus.loading &&
                    state.popularVenues.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4C1CDD),
                      ),
                    ),
                  )
                else
                  for (final PartyVenueEntity venue in state.popularVenues)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: _PopularVenueCard(
                        venue: venue,
                        onTap: () => PartyNavigator.push(
                          context,
                          PartyVenueDetailPage(venueId: venue.id),
                        ),
                      ),
                    ),

                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Hero Banner with Celebration Crowd Image, Stage Lights, and Organic Bottom Scoop
class _PartyHeroBanner extends StatelessWidget {
  const _PartyHeroBanner();

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = 330.0 + topPadding;

    return ClipPath(
      clipper: const PartyHeroClipper(),
      child: Container(
        height: heroHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1A0336),
        ),
        child: Stack(
          children: [
            // 1. Celebration Crowd Background Image with Purple Stage Lights
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?fit=crop&w=900&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.network(
                  'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?fit=crop&w=900&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF5B108E),
                          Color(0xFF280447),
                          Color(0xFF130124),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Rich Royal Purple & Night Club Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA3B0764),
                      Color(0xCC200445),
                      Color(0xFA16022B),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Stage Light Glow Highlights
            Positioned(
              right: -30,
              top: topPadding + 10,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD946EF).withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              top: topPadding + 40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 4. Content (Top bar, Headings, Explore Venues button)
            Padding(
              padding: EdgeInsets.fromLTRB(22, topPadding + 12, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar: "📍 Hyderabad ⌵" and Notification Bell
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _snack(context, 'Select Location'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Hyderabad',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _snack(context, 'No new notifications'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Heading: "Make Your\nParty Special"
                  const Text(
                    'Make Your\nParty Special',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle: "Book the Perfect Venue\nfor Every Celebration"
                  Text(
                    'Book the Perfect Venue\nfor Every Celebration',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Pill Button: "Explore Venues →"
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => PartyNavigator.push(
                      context,
                      const PartyCategoryPage(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Venues →',
                            style: TextStyle(
                              color: Color(0xFF140D43),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of 4 Category Cards: Birthday, Wedding, Corporate, Others
class _CategoryPillsRow extends StatelessWidget {
  const _CategoryPillsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Birthday
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CategoryCard(
              label: 'Birthday',
              iconWidget: const _BirthdayCakeIcon(),
              onTap: () => PartyNavigator.push(
                context,
                const PartyVenueListPage(
                  title: 'Birthday Parties',
                  categoryId: 'birthday',
                ),
              ),
            ),
          ),
        ),

        // 2. Wedding
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CategoryCard(
              label: 'Wedding',
              iconWidget: const _WeddingRingsIcon(),
              onTap: () => PartyNavigator.push(
                context,
                const PartyVenueListPage(
                  title: 'Wedding Functions',
                  categoryId: 'wedding',
                ),
              ),
            ),
          ),
        ),

        // 3. Corporate
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CategoryCard(
              label: 'Corporate',
              iconWidget: const _CorporateGlassesIcon(),
              onTap: () => PartyNavigator.push(
                context,
                const PartyVenueListPage(
                  title: 'Corporate Events',
                  categoryId: 'corporate',
                ),
              ),
            ),
          ),
        ),

        // 4. Others
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CategoryCard(
              label: 'Others',
              iconWidget: const _OthersStarIcon(),
              onTap: () => PartyNavigator.push(
                context,
                const PartyCategoryPage(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Single Category Card matching the rounded soft lavender card design
class _CategoryCard extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 94,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEFEBFD),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B3BF5).withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 42,
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF140D43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Illustrated Category Icons matching the exact screenshot:
// ---------------------------------------------------------------------------

/// Birthday Cake: 2-Tier Pink Cake with 3 Candles
class _BirthdayCakeIcon extends StatelessWidget {
  const _BirthdayCakeIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 Candles on top
          Positioned(
            top: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _candle(const Color(0xFFFFB800)),
                const SizedBox(width: 6),
                _candle(const Color(0xFFF43F5E)),
                const SizedBox(width: 6),
                _candle(const Color(0xFFFFB800)),
              ],
            ),
          ),

          // Cake Top Tier
          Positioned(
            top: 15,
            child: Container(
              width: 28,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFB7185),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Cake Bottom Tier
          Positioned(
            bottom: 3,
            child: Container(
              width: 38,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE047),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _candle(Color flame) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 5,
            decoration: BoxDecoration(
              color: flame,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 2.5,
            height: 7,
            color: const Color(0xFFFFFBEB),
          ),
        ],
      );
}

/// Wedding Rings: Interlocking Golden Rings with Diamond
class _WeddingRingsIcon extends StatelessWidget {
  const _WeddingRingsIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Ring
          Positioned(
            left: 5,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 3.5,
                ),
              ),
            ),
          ),
          // Diamond Sparkle on top of left ring
          Positioned(
            left: 12,
            top: 4,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          // Right Ring
          Positioned(
            right: 5,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFBBF24),
                  width: 3.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Corporate: Clinking Champagne Celebration Glasses
class _CorporateGlassesIcon extends StatelessWidget {
  const _CorporateGlassesIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Glass
          Positioned(
            left: 7,
            top: 8,
            child: Transform.rotate(
              angle: -0.30,
              child: const Icon(
                Icons.wine_bar_rounded,
                color: Color(0xFF6F35FF),
                size: 26,
              ),
            ),
          ),
          // Right Glass
          Positioned(
            right: 7,
            top: 8,
            child: Transform.rotate(
              angle: 0.30,
              child: const Icon(
                Icons.wine_bar_rounded,
                color: Color(0xFF4C1CDD),
                size: 26,
              ),
            ),
          ),
          // Bubbles on top
          Positioned(
            top: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bubble(4),
                const SizedBox(width: 4),
                _bubble(5),
                const SizedBox(width: 4),
                _bubble(3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF818CF8),
          shape: BoxShape.circle,
        ),
      );
}

/// Others: 3D Golden-Amber 5-Pointed Star
class _OthersStarIcon extends StatelessWidget {
  const _OthersStarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.star_rounded,
        color: Color(0xFFF59E0B),
        size: 34,
      ),
    );
  }
}

/// Popular Venue Card matching screenshot:
/// Large venue photo, white outline heart button, "Royal Garden Banquet", "₹25,000 onwards", and "★ 4.6 (1.2k reviews)".
class _PopularVenueCard extends StatelessWidget {
  final PartyVenueEntity venue;
  final VoidCallback onTap;

  const _PopularVenueCard({
    required this.venue,
    required this.onTap,
  });

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
            // 1. Banquet Hall Cover Photo with Favorite Heart Button
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    photoUrl,
                    height: 195,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 195,
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

                  // Top-Right White Outline Heart Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: BlocBuilder<PartyFavoritesBloc, PartyFavoritesState>(
                      builder: (context, favState) {
                        final isFav = favState.isFavorite(venue.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context
                              .read<PartyFavoritesBloc>()
                              .add(PartyFavoriteToggled(venue.id)),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Drop shadow for visibility on light photo areas
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

            // 2. Title & Starting Price Row
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

            const SizedBox(height: 5),

            // 3. Rating & Review Count
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
