import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/party_colors.dart';
import '../../core/party_formatters.dart';
import '../../core/party_injector.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_venue_detail_bloc.dart';
import '../party_navigator.dart';
import '../widgets/party_widgets.dart';
import 'party_booking_page.dart';

/// Screen 3: venue details.
class PartyVenueDetailPage extends StatelessWidget {
  const PartyVenueDetailPage({super.key, required this.venueId});
  final String venueId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartyInjector.I.venueDetailBloc()
        ..add(PartyVenueDetailStarted(venueId)),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartyVenueDetailBloc, PartyVenueDetailState>(
      builder: (context, state) {
        final venue = state.venue;
        if (venue == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: state.status == PartyStatus.failure
                  ? Text(state.error ?? 'Could not load this venue.')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Gallery(venue: venue, index: state.imageIndex),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venue.name,
                              style: AppTypography.displayMedium
                                  .copyWith(fontSize: 24)),
                          const SizedBox(height: 6),
                          PartyRatingRow(venue: venue, fontSize: 14),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 18, color: PartyColors.subtle),
                              const SizedBox(width: 4),
                              Text(venue.location,
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('${PartyFormatters.rupee(venue.priceFrom)} onwards',
                              style: AppTypography.titleLarge.copyWith(
                                  color: PartyColors.primary,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _Amenity(
                                icon: Icons.groups_rounded,
                                top: '${venue.capacity}',
                                bottom: 'Capacity',
                              ),
                              _Amenity(
                                icon: Icons.ac_unit_rounded,
                                top: venue.hasAc ? 'AC' : 'Non-AC',
                                bottom: 'Hall',
                              ),
                              _Amenity(
                                icon: Icons.local_parking_rounded,
                                top: 'Parking',
                                bottom: venue.hasParking ? 'Available' : 'Not Available',
                              ),
                              _Amenity(
                                icon: Icons.room_service_rounded,
                                top: 'Catering',
                                bottom: venue.hasCatering ? 'Available' : 'Not Available',
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text('About Venue',
                              style: AppTypography.titleMedium
                                  .copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            venue.description,
                            maxLines: state.expanded ? null : 3,
                            overflow: state.expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                                fontSize: 14,
                                height: 1.45,
                                color: PartyColors.muted),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () => context
                                  .read<PartyVenueDetailBloc>()
                                  .add(const PartyVenueDetailReadMoreToggled()),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(state.expanded ? 'Show Less' : 'Read More',
                                      style: AppTypography.labelMedium.copyWith(
                                          color: PartyColors.primary,
                                          fontWeight: FontWeight.w700)),
                                  Icon(
                                    state.expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: PartyColors.primary,
                                    size: 20,
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
              _BottomBar(venue: venue),
            ],
          ),
        );
      },
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.venue, required this.index});
  final PartyVenueEntity venue;
  final int index;

  Widget _circle(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(.3), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final count = venue.imageCount;
    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: count,
            onPageChanged: (i) => context
                .read<PartyVenueDetailBloc>()
                .add(PartyVenueDetailImageChanged(i)),
            itemBuilder: (_, i) => PartyImage(
              url: i < venue.imageUrls.length ? venue.imageUrls[i] : '',
              seed: venue.id.hashCode + i,
              width: double.infinity,
            ),
          ),
          Positioned(
            top: top + 8,
            left: 14,
            right: 14,
            child: Row(
              children: [
                _circle(Icons.arrow_back_rounded,
                    () => Navigator.maybePop(context)),
                const Spacer(),
                PartyFavoriteButton(venueId: venue.id, size: 38),
                const SizedBox(width: 10),
                _circle(Icons.ios_share_rounded, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share ${venue.name}')),
                  );
                }),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${index + 1} / $count',
                  style: AppTypography.labelMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Amenity extends StatelessWidget {
  const _Amenity({required this.icon, required this.top, required this.bottom});
  final IconData icon;
  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: PartyColors.tile,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: PartyColors.primary, size: 26),
            const SizedBox(height: 4),
            Text(top,
                maxLines: 1,
                style: AppTypography.labelMedium
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5)),
            Text(bottom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(color: PartyColors.muted, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.venue});
  final PartyVenueEntity venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PartyColors.border.withOpacity(.6))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: BlocBuilder<PartyFavoritesBloc, PartyFavoritesState>(
                builder: (context, fav) {
                  final saved = fav.isFavorite(venue.id);
                  return CustomButton(
                    text: saved ? 'Saved' : 'Save',
                    icon: saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    backgroundColor: Colors.white,
                    textColor: PartyColors.primary,
                    borderSide:
                        const BorderSide(color: PartyColors.primary, width: 1.4),
                    onPressed: () => context
                        .read<PartyFavoritesBloc>()
                        .add(PartyFavoriteToggled(venue.id)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 13,
              child: CustomButton(
                text: 'Book Now',
                backgroundColor: PartyColors.primary,
                onPressed: () => PartyNavigator.push(
                    context, PartyBookingPage(venue: venue)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
