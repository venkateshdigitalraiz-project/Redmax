import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';

import '../../data/datasources/places_remote_data_source.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/usecases/get_place_predictions_usecase.dart';
import '../bloc/places_autocomplete_bloc.dart';

/// Clean model representing a selected place with name and optional coordinates.
class CarpoolPlaceResult extends Equatable {
  final String name;
  final double? lat;
  final double? lng;

  const CarpoolPlaceResult({
    required this.name,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [name, lat, lng];
}

/// Rapido-style Location Picker Page integrated with Google Places Autocomplete API.
/// Adheres to Clean Architecture with BLoC.
class RapidoPlaceSearchPage extends StatelessWidget {
  final String title;
  final String initialValue;
  final bool isPickup;
  final String apiKey;

  const RapidoPlaceSearchPage({
    super.key,
    required this.title,
    this.initialValue = '',
    this.isPickup = true,
    this.apiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU',
  });

  /// Static helper to open the place search screen and return the chosen location result.
  static Future<CarpoolPlaceResult?> show(
    BuildContext context, {
    required String title,
    String initialValue = '',
    bool isPickup = true,
    String apiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU',
  }) {
    return Navigator.of(context).push<CarpoolPlaceResult>(
      MaterialPageRoute(
        builder: (_) => RapidoPlaceSearchPage(
          title: title,
          initialValue: initialValue,
          isPickup: isPickup,
          apiKey: apiKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clean Architecture instantiation
    final remoteDataSource = GooglePlacesRemoteDataSourceImpl(apiKey: apiKey);
    final repository = PlacesRepositoryImpl(remoteDataSource);
    final useCase = GetPlacePredictionsUseCase(repository);

    return BlocProvider<PlacesAutocompleteBloc>(
      create: (_) => PlacesAutocompleteBloc(getPlacePredictions: useCase)
        ..add(
          initialValue.trim().isNotEmpty
              ? PlaceQueryChanged(initialValue.trim())
              : const PlaceQueryInitialRequested(),
        ),
      child: _RapidoPlaceSearchView(
        title: title,
        initialValue: initialValue,
        isPickup: isPickup,
      ),
    );
  }
}

class _RapidoPlaceSearchView extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool isPickup;

  const _RapidoPlaceSearchView({
    required this.title,
    required this.initialValue,
    required this.isPickup,
  });

  @override
  State<_RapidoPlaceSearchView> createState() => _RapidoPlaceSearchViewState();
}

class _RapidoPlaceSearchViewState extends State<_RapidoPlaceSearchView> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      context.read<PlacesAutocompleteBloc>().add(PlaceQueryChanged(query));
    });
  }

  void _onPlaceSelected(PlacePredictionEntity place) {
    // Return the concise main text (e.g., "Gachibowli") or full description
    final chosen = place.mainText.isNotEmpty ? place.mainText : place.description;
    final coords = CarpoolDistanceCalculator.resolveCoordinates(
      chosen,
      preferredLat: place.lat,
      preferredLng: place.lng,
      defaultLat: 0.0,
      defaultLng: 0.0,
    );
    Navigator.of(context).pop(CarpoolPlaceResult(
      name: chosen,
      lat: coords.lat,
      lng: coords.lng,
    ));
  }

  void _onUseCurrentLocation() {
    Navigator.of(context).pop(const CarpoolPlaceResult(
      name: 'Current Location',
      lat: 17.3850,
      lng: 78.4867,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinColor = widget.isPickup
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar (Rapido style) ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08140D43),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EEFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF140D43),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isPickup ? 'Pick-up point' : 'Drop-off point',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B658C),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Rapido-Style Input Box ──────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2DCF9),
                    width: 1.3,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    // Location indicator pin / dot
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: pinColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.isPickup
                            ? Icons.circle
                            : Icons.location_on_rounded,
                        color: pinColor,
                        size: widget.isPickup ? 11 : 16,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Search text field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D43),
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: (text) {
                          setState(() {});
                          _onSearchChanged(text);
                        },
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            final name = text.trim();
                            final geo = CarpoolDistanceCalculator.findGeo(name);
                            Navigator.of(context).pop(CarpoolPlaceResult(
                              name: name,
                              lat: geo?.lat,
                              lng: geo?.lng,
                            ));
                          }
                        },
                        decoration: InputDecoration(
                          hintText: widget.isPickup
                              ? 'Enter pickup area, colony, or landmark...'
                              : 'Enter destination, city, or landmark...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9E98BE),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),

                    // Clear button
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() {});
                          context
                              .read<PlacesAutocompleteBloc>()
                              .add(const PlaceQueryCleared());
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.cancel_rounded,
                            color: Color(0xFF8A84A7),
                            size: 19,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Suggestions List & Current Location ─────────────────────────
            Expanded(
              child: BlocBuilder<PlacesAutocompleteBloc, PlacesAutocompleteState>(
                builder: (context, state) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // "Use Current Location" Quick Action (Rapido Signature)
                      InkWell(
                        onTap: _onUseCurrentLocation,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEDE8FF),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE8FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF3815D8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use current location',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3815D8),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tap to detect GPS position',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B658C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF6B658C),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.query.trim().isEmpty
                                  ? 'SEARCH LOCATION'
                                  : 'SEARCH RESULTS',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B658C),
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (state.status == PlacesAutocompleteStatus.loading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3815D8),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Results Card Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEDE8FF),
                            width: 1.1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06140D43),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildResultsList(state),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(PlacesAutocompleteState state) {
    if (state.status == PlacesAutocompleteStatus.loading &&
        state.predictions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3815D8),
              ),
              SizedBox(height: 12),
              Text(
                'Searching places...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B658C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.predictions.isEmpty) {
      final isQueryEmpty = state.query.trim().isEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Icon(
              isQueryEmpty ? Icons.search_rounded : Icons.location_off_rounded,
              color: const Color(0xFF9E98BE),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              isQueryEmpty
                  ? 'Search for a location'
                  : 'No matching locations found',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isQueryEmpty
                  ? 'Type an address, landmark, or area'
                  : 'Try typing a different place or area',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < state.predictions.length; i++) ...[
          _PlacePredictionTile(
            prediction: state.predictions[i],
            onTap: () => _onPlaceSelected(state.predictions[i]),
          ),
          if (i < state.predictions.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 58,
              color: Color(0xFFF1EEFC),
            ),
        ],
      ],
    );
  }
}

class _PlacePredictionTile extends StatelessWidget {
  final PlacePredictionEntity prediction;
  final VoidCallback onTap;

  const _PlacePredictionTile({
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = CarpoolDistanceCalculator.classifyType(
      prediction.mainText,
      prediction.secondaryText,
    );
    final isVillage = type.toLowerCase().contains('village');
    final isTown = type.toLowerCase().contains('town');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rapido location marker
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isVillage
                    ? const Color(0xFFDCFCE7)
                    : (isTown
                        ? const Color(0xFFF3E8FF)
                        : const Color(0xFFF1EEFC)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVillage
                    ? Icons.home_rounded
                    : (isTown
                        ? Icons.location_city_rounded
                        : Icons.location_on_rounded),
                color: isVillage
                    ? const Color(0xFF15803D)
                    : (isTown
                        ? const Color(0xFF7E22CE)
                        : const Color(0xFF3815D8)),
                size: 17,
              ),
            ),
            const SizedBox(width: 12),

            // Place texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF140D43),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isVillage
                              ? const Color(0xFFDCFCE7)
                              : (isTown
                                  ? const Color(0xFFF3E8FF)
                                  : const Color(0xFFDBEAFE)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isVillage
                                ? const Color(0xFF15803D)
                                : (isTown
                                    ? const Color(0xFF7E22CE)
                                    : const Color(0xFF1D4ED8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          prediction.secondaryText.isNotEmpty
                              ? prediction.secondaryText
                              : 'India',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B658C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.north_west_rounded,
              color: Color(0xFFB0AACD),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

