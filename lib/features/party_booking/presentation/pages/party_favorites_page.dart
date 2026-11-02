import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_nav_cubit.dart';
import '../party_navigator.dart';
import '../widgets/party_widgets.dart';
import 'party_venue_detail_page.dart';

class PartyFavoritesPage extends StatelessWidget {
  const PartyFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PartyHeaderBar(
          title: 'Favorites',
          onBack: () => context.read<PartyNavCubit>().select(0),
        ),
        Expanded(
          child: BlocBuilder<PartyFavoritesBloc, PartyFavoritesState>(
            builder: (context, state) {
              if (state.venues.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No favorites yet.\nTap the heart on a venue to save it here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.venues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, i) {
                  final v = state.venues[i];
                  return PartyVenueCard(
                    venue: v,
                    onTap: () => PartyNavigator.push(
                        context, PartyVenueDetailPage(venueId: v.id)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
