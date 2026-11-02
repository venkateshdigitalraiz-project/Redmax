import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/party_colors.dart';
import '../../core/party_injector.dart';
import '../../core/party_status.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_category_bloc.dart';
import '../party_navigator.dart';
import '../widgets/party_widgets.dart';
import 'party_venue_detail_page.dart';
import 'party_venue_list_page.dart';

/// Screen 2: "Select Category" with search.
class PartyCategoryPage extends StatelessWidget {
  const PartyCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PartyInjector.I.categoryBloc()..add(const PartyCategoryStarted()),
      child: const _CategoryView(),
    );
  }
}

class _CategoryView extends StatelessWidget {
  const _CategoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<PartyCategoryBloc, PartyCategoryState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text('Select Category',
                            textAlign: TextAlign.center,
                            style: AppTypography.titleLarge
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: TextField(
                    onChanged: (v) => context
                        .read<PartyCategoryBloc>()
                        .add(PartyCategorySearchChanged(v)),
                    decoration: InputDecoration(
                      hintText: 'Search venues...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: PartyColors.chip,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: PartyColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: state.isSearchMode
                      ? _Results(state: state)
                      : _Grid(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.state});
  final PartyCategoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == PartyStatus.loading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      itemCount: state.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .96,
      ),
      itemBuilder: (context, i) {
        final c = state.categories[i];
        return _CategoryTile(
          category: c,
          onTap: () => PartyNavigator.push(
            context,
            PartyVenueListPage(title: c.name, categoryId: c.id),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final PartyCategoryEntity category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = PartyCategoryVisual.of(category.id);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: PartyColors.tile,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: PartyColors.primary.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: PartyImage(
                url: category.imageUrl,
                gradient: visual.gradient,
                icon: visual.icon,
                radius: const BorderRadius.vertical(top: Radius.circular(16)),
                width: double.infinity,
              ),
            ),
            Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 14, height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});
  final PartyCategoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.results.isEmpty) {
      return Center(
        child: Text('No venues match "${state.query}".',
            style: AppTypography.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) {
        final v = state.results[i];
        return PartyVenueCard(
          venue: v,
          onTap: () => PartyNavigator.push(
              context, PartyVenueDetailPage(venueId: v.id)),
        );
      },
    );
  }
}
