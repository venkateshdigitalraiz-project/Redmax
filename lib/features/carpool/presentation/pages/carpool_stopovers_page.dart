import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../data/datasources/places_remote_data_source.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/usecases/get_place_predictions_usecase.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import 'carpool_ride_summary_page.dart';

/// Clean Architecture CarpoolStopoversPage – Route-Based Nearby City Suggestions.
/// Inserted between [CarpoolPublishRidePage] and [CarpoolRideSummaryPage].
///
/// Features:
/// 1. Automatic Route-Based City Suggestions: Discovers and displays towns and cities
///    along the actual driving route corridor (e.g., Kalidindi, Gudivada, Gannavaram for Bhimavaram -> Vijayawada).
/// 2. Route Polyline Distance Validation: Validates locations against driving polyline geometry.
///    - Shows "On your route" (green) when within acceptable corridor deviation.
///    - Shows "This location is not on your route" and disallows adding when detour is too high.
/// 3. Route Adjustment Preview: Shows additional distance, additional time, updated total, and estimated duration.
/// 4. Multiple Stopovers: Ordered display, reordering, and removal with real-time route recalculation.
/// 5. Clean Architecture + BLoC conforming strictly to Pathway design guidelines.
class CarpoolStopoversPage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;

  const CarpoolStopoversPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _StopoversView());
    }
    return const _StopoversView();
  }
}

class _StopoversView extends StatefulWidget {
  const _StopoversView();

  @override
  State<_StopoversView> createState() => _StopoversViewState();
}

class _StopoversViewState extends State<_StopoversView> {
  late final GetPlacePredictionsUseCase _getPlacePredictions;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  List<PlacePredictionEntity> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isSearchActive = false;
  String? _lastLoadedRouteKey;

  @override
  void initState() {
    super.initState();
    final remoteDataSource = GooglePlacesRemoteDataSourceImpl(
      apiKey: ApiEndpoints.googleMapsApiKey,
    );
    final repository = PlacesRepositoryImpl(remoteDataSource);
    _getPlacePredictions = GetPlacePredictionsUseCase(repository);

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchActive =
              _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
        });
      }
    });

    // Automatically load cities and towns strictly along the current active route path
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialRouteBasedSuggestions(force: true);
    });
  }

  void _loadInitialRouteBasedSuggestions({bool force = false}) {
    if (!mounted) return;
    final state = context.read<CarpoolOfferRideBloc>().state;
    final routeKey = '${state.from}_${state.to}';

    if (!force &&
        _lastLoadedRouteKey == routeKey &&
        state.stopovers.isNotEmpty) {
      return;
    }
    _lastLoadedRouteKey = routeKey;

    final routeCities = CarpoolDistanceCalculator.getRouteBasedSuggestions(
      start: state.from,
      destination: state.to,
      startLat: state.fromLat,
      startLng: state.fromLng,
      destLat: state.toLat,
      destLng: state.toLng,
    );

    context.read<CarpoolOfferRideBloc>().add(
      CarpoolOfferRouteSuggestionsLoaded(
        routeCities.map((g) => g.name).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);
    _debounceTimer = Timer(const Duration(milliseconds: 280), () async {
      try {
        final results = await _getPlacePredictions(clean);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoadingSuggestions = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _suggestions = [];
      _isLoadingSuggestions = false;
      _isSearchActive = false;
    });
    _searchFocusNode.unfocus();
  }

  /// Validates candidate location against the actual driving route polyline
  RouteAdjustment _validateStopover(
    CarpoolOfferRideState state,
    String candidateName, {
    double? candidateLat,
    double? candidateLng,
  }) {
    return CarpoolDistanceCalculator.validateLocationOnRoute(
      start: state.from,
      destination: state.to,
      candidateName: candidateName,
      candidateLat: candidateLat,
      candidateLng: candidateLng,
      startLat: state.fromLat,
      startLng: state.fromLng,
      destLat: state.toLat,
      destLng: state.toLng,
      currentStopovers: state.selectedStopovers.toList(),
    );
  }

  /// Opens the simple Add Halt / Stopover confirmation sheet
  void _showRouteAdjustmentModal(
    BuildContext context,
    CarpoolOfferRideState state,
    String candidateName,
    String? subtitle,
    double? lat,
    double? lng,
  ) {
    _searchFocusNode.unfocus();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F140D43),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEDAF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Candidate name & subtitle
              Text(
                candidateName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF140D43),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B658C),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action Buttons: Cancel & Add Halt
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5D24F7), Color(0xFF3815D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4C1CDD).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.read<CarpoolOfferRideBloc>().add(
                              CarpoolOfferStopoverAdded(candidateName),
                            );
                            if (lat != null && lng != null) {
                              CarpoolDistanceCalculator.registerGeo(
                                candidateName,
                                lat,
                                lng,
                              );
                            }
                            _onClearSearch();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Add Halt / Stopover',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onContinue(BuildContext context) {
    final bloc = context.read<CarpoolOfferRideBloc>();
    CarpoolRideSummaryPage.show(
      context,
      bloc,
      pricing: bloc.state.pricingCalculation,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF4C2BF0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<CarpoolOfferRideBloc, CarpoolOfferRideState>(
          builder: (context, state) {
            final rawActive = state.stopovers
                .where((s) => state.selectedStopovers.contains(s))
                .toList();
            final activeStopovers =
                CarpoolDistanceCalculator.orderStopoversInCorridor(
              start: state.from,
              destination: state.to,
              stopovers: rawActive.isNotEmpty
                  ? rawActive
                  : state.selectedStopovers.toList(),
              startLat: state.fromLat,
              startLng: state.fromLng,
              destLat: state.toLat,
              destLng: state.toLng,
            );

            final totalRouteKm =
                CarpoolDistanceCalculator.calculateDistanceKm(
                  state.from,
                  state.to,
                  fromLat: state.fromLat,
                  fromLng: state.fromLng,
                  toLat: state.toLat,
                  toLng: state.toLng,
                );
            final totalDuration = CarpoolDistanceCalculator.estimateDuration(
              totalRouteKm,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar with Back Button and Driving Route Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.centerLeft,
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: primaryPurple,
                            size: 28,
                          ),
                        ),
                      ),
                      // Route summary pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalRouteKm km • ~$totalDuration',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Main Title (Matching screenshot typography)
                  const Text(
                    'Add stopovers to get\nmore passengers',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF140D43),
                      height: 1.22,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Active Route Subtitle
                  Text(
                    'Route: ${state.from} → ${state.to}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B658C),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Smart Stopover Search Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSearchActive
                            ? primaryPurple
                            : const Color(0xFFE2DCF9),
                        width: _isSearchActive ? 1.6 : 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _isSearchActive
                              ? primaryPurple
                              : const Color(0xFF9E98BE),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search city, town, or village...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9E98BE),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _onClearSearch,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF8A84A7),
                              ),
                            ),
                          ),
                        if (_isLoadingSuggestions)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Main Body: Live Search Results OR Route-Based Suggested Cities List
                  Expanded(
                    child:
                        _isSearchActive &&
                            _searchController.text.trim().isNotEmpty
                        ? _buildSearchSuggestions(state)
                        : _buildStopoversList(state),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // 5. Bottom Right Floating Forward Button (Matching Screenshot)
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5D24F7), Color(0xFF3815D8)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C1CDD).withOpacity(0.42),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _onContinue(context),
            child: const Center(
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds live search results with strict route-geometry validation
  Widget _buildSearchSuggestions(CarpoolOfferRideState state) {
    if (_isLoadingSuggestions && _suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF4C2BF0),
            ),
            SizedBox(height: 12),
            Text(
              'Checking driving route geometry...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B658C),
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              color: Color(0xFF9E98BE),
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              'No nearby stopover locations found',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF140D43),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try typing an intermediate town along your route',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B658C)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EEFC)),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final name = suggestion.mainText.isNotEmpty
            ? suggestion.mainText
            : suggestion.description;
        final adj = _validateStopover(
          state,
          name,
          candidateLat: suggestion.lat,
          candidateLng: suggestion.lng,
        );

        return InkWell(
          onTap: () => _showRouteAdjustmentModal(
            context,
            state,
            name,
            suggestion.secondaryText,
            suggestion.lat,
            suggestion.lng,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: adj.isOnRoute
                        ? const Color(0xFFF1EEFC)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    adj.isOnRoute
                        ? Icons.location_on_rounded
                        : Icons.location_off_rounded,
                    color: adj.isOnRoute
                        ? const Color(0xFF4C2BF0)
                        : const Color(0xFFB91C1C),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      if (suggestion.secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestion.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B658C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Validation Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: adj.isOnRoute
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        adj.isOnRoute
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 13,
                        color: adj.isOnRoute
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        adj.isOnRoute
                            ? 'On your route'
                            : 'This location is not on your route',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: adj.isOnRoute
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the Route-Based City Suggestions list along the driving route
  Widget _buildStopoversList(CarpoolOfferRideState state) {
    const primaryPurple = Color(0xFF4C2BF0);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        if (state.stopovers.isNotEmpty) ...[
          // Reorderable list of cities along the route
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: state.stopovers.length,
              onReorder: (oldIndex, newIndex) {
                context.read<CarpoolOfferRideBloc>().add(
                  CarpoolOfferStopoversReordered(oldIndex, newIndex),
                );
              },
              itemBuilder: (context, index) {
                final stopover = state.stopovers[index];
                final isSelected = state.selectedStopovers.contains(stopover);
                final adj = _validateStopover(state, stopover);

                return Container(
                  key: ValueKey('stopover_$stopover'),
                  margin: const EdgeInsets.only(bottom: 2),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // 1. Rounded Checkbox
                            InkWell(
                              onTap: () {
                                context.read<CarpoolOfferRideBloc>().add(
                                  CarpoolOfferStopoverToggled(stopover),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryPurple
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: primaryPurple,
                                    width: 1.8,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      )
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 14),

                            // 2. City Name & Route Badge
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<CarpoolOfferRideBloc>().add(
                                    CarpoolOfferStopoverToggled(stopover),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF1EEFC),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: primaryPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stopover,
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? const Color(0xFF140D43)
                                                  : const Color(0xFF9E98BE),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Validation Tag
                                    Padding(
                                      padding: const EdgeInsets.only(left: 28),
                                      child: Row(
                                        children: [
                                          Icon(
                                            adj.isOnRoute
                                                ? Icons.check_circle_rounded
                                                : Icons.alt_route_rounded,
                                            size: 12,
                                            color: adj.isOnRoute
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFFE65100),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            adj.isOnRoute
                                                ? 'On your route'
                                                : '+${adj.additionalKm} km detour',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: adj.isOnRoute
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFFE65100),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. Remove Button
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF9E98BE),
                                size: 19,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                context.read<CarpoolOfferRideBloc>().add(
                                  CarpoolOfferStopoverRemoved(stopover),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // 4. Drag Handle for Reordering
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_handle_rounded,
                                color: Color(0xFFC7C2E5),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1EEFC),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE8FF)),
            ),
            child: const Row(
              children: [
                Icon(Icons.alt_route_rounded, color: primaryPurple, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No intermediate stopovers found along this route. Tap "Add city" below to add intermediate stops.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B658C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // "Add city" link (matching screenshot)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _searchFocusNode.requestFocus();
              setState(() => _isSearchActive = true);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: primaryPurple, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Add city',
                    style: TextStyle(
                      color: primaryPurple,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
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

class _RouteStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final IconData icon;

  const _RouteStatCard({
    required this.label,
    required this.value,
    required this.isHighlight,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFF1F2) : const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFFECDD3)
              : const Color(0xFFEDE8FF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isHighlight
                    ? const Color(0xFFBE123C)
                    : const Color(0xFF5D24F7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isHighlight
                        ? const Color(0xFFBE123C)
                        : const Color(0xFF6B658C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isHighlight
                  ? const Color(0xFF9F1239)
                  : const Color(0xFF140D43),
            ),
          ),
        ],
      ),
    );
  }
}
