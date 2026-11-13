import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/constants/api_endpoints.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/datasources/places_remote_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../../domain/usecases/get_place_predictions_usecase.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../bloc/places_autocomplete_bloc.dart';

/// Rapido-Style Route Selection Screen.
/// Clean Architecture + BLoC integration:
/// Displays both "From" (Pick-up) and "To" (Drop-off) location inputs in Rapido style.
/// The Google Places suggestions list is displayed ONLY when actively searching for a location.
class CarpoolSelectRoutePage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;
  final String apiKey;

  const CarpoolSelectRoutePage({
    super.key,
    this.bloc,
    this.apiKey = ApiEndpoints.googleMapsApiKey,
  });

  /// Navigates to [CarpoolSelectRoutePage] sharing the given [CarpoolOfferRideBloc].
  static Future<void> show(
    BuildContext context,
    CarpoolOfferRideBloc bloc, {
    String apiKey = ApiEndpoints.googleMapsApiKey,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CarpoolSelectRoutePage(bloc: bloc, apiKey: apiKey),
        ),
      ),
    );
  }

  Widget _buildWithPlacesBloc(BuildContext context) {
    final remoteDataSource = GooglePlacesRemoteDataSourceImpl(apiKey: apiKey);
    final repository = PlacesRepositoryImpl(remoteDataSource);
    final useCase = GetPlacePredictionsUseCase(repository);

    return BlocProvider<PlacesAutocompleteBloc>(
      create: (_) => PlacesAutocompleteBloc(getPlacePredictions: useCase),
      child: const _RapidoRouteSearchView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _buildWithPlacesBloc(context),
      );
    }

    try {
      context.read<CarpoolOfferRideBloc>();
      return _buildWithPlacesBloc(context);
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return BlocProvider(
        create: (_) => CarpoolOfferRideBloc(
          publishRide: CarpoolPublishRideUseCase(repository),
        ),
        child: _buildWithPlacesBloc(context),
      );
    }
  }
}

class _RapidoRouteSearchView extends StatefulWidget {
  const _RapidoRouteSearchView();

  @override
  State<_RapidoRouteSearchView> createState() => _RapidoRouteSearchViewState();
}

class _RapidoRouteSearchViewState extends State<_RapidoRouteSearchView> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final FocusNode _fromFocus;
  late final FocusNode _toFocus;

  bool _isEditingFrom = true;
  bool _isSearching = false;
  Timer? _debounceTimer;

  double? _fromLat;
  double? _fromLng;
  double? _toLat;
  double? _toLng;

  void _onQuickLocationSelected(String locationName, {double? lat, double? lng}) {
    final coords = CarpoolDistanceCalculator.resolveCoordinates(
      locationName,
      preferredLat: lat,
      preferredLng: lng,
      defaultLat: 0.0,
      defaultLng: 0.0,
    );

    final bloc = context.read<CarpoolOfferRideBloc>();
    if (_isEditingFrom) {
      _fromController.text = locationName;
      _fromLat = coords.lat;
      _fromLng = coords.lng;
      bloc.add(CarpoolOfferFromChanged(locationName, lat: coords.lat, lng: coords.lng));
      if (_toController.text.trim().isEmpty ||
          _toController.text.trim().toLowerCase() ==
              locationName.toLowerCase()) {
        _toFocus.requestFocus();
        setState(() {
          _isEditingFrom = false;
          _isSearching = true;
        });
      } else {
        FocusScope.of(context).unfocus();
        setState(() => _isSearching = false);
      }
    } else {
      _toController.text = locationName;
      _toLat = coords.lat;
      _toLng = coords.lng;
      bloc.add(CarpoolOfferToChanged(locationName, lat: coords.lat, lng: coords.lng));
      FocusScope.of(context).unfocus();
      setState(() => _isSearching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final s = context.read<CarpoolOfferRideBloc>().state;
    _fromController = TextEditingController(text: s.from);
    _toController = TextEditingController(text: s.to);
    _fromLat = s.fromLat != 0.0 ? s.fromLat : null;
    _fromLng = s.fromLng != 0.0 ? s.fromLng : null;
    _toLat = s.toLat != 0.0 ? s.toLat : null;
    _toLng = s.toLng != 0.0 ? s.toLng : null;
    _fromFocus = FocusNode();
    _toFocus = FocusNode();

    _fromFocus.addListener(() {
      if (_fromFocus.hasFocus) {
        setState(() {
          _isEditingFrom = true;
          _isSearching = true;
        });
        _triggerSearch(_fromController.text);
      }
    });

    _toFocus.addListener(() {
      if (_toFocus.hasFocus) {
        setState(() {
          _isEditingFrom = false;
          _isSearching = true;
        });
        _triggerSearch(_toController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.read<PlacesAutocompleteBloc>().add(PlaceQueryChanged(query));
    });
  }

  Future<void> _onPlaceSelected(PlacePredictionEntity place) async {
    final chosen = place.mainText.isNotEmpty
        ? place.mainText
        : place.description;

    var lat = place.lat;
    var lng = place.lng;
    if ((lat == null || lng == null || (lat == 0.0 && lng == 0.0)) &&
        place.description.trim().isNotEmpty) {
      final fetched = await CarpoolDistanceCalculator.fetchGeocodeCoordinates(
        place.placeId.isNotEmpty ? place.placeId : place.description,
        isPlaceId: place.placeId.isNotEmpty && !place.placeId.startsWith('osm_'),
      );
      if (fetched != null) {
        lat = fetched.lat;
        lng = fetched.lng;
      }
    }

    var coords = CarpoolDistanceCalculator.resolveCoordinates(
      chosen,
      preferredLat: lat,
      preferredLng: lng,
      defaultLat: 0.0,
      defaultLng: 0.0,
    );

    if ((coords.lat == 0.0 || coords.lng == 0.0) &&
        place.description.trim().isNotEmpty) {
      coords = CarpoolDistanceCalculator.resolveCoordinates(
        place.description,
        preferredLat: lat,
        preferredLng: lng,
      );
    }

    final resolvedLat = coords.lat != 0.0 ? coords.lat : lat;
    final resolvedLng = coords.lng != 0.0 ? coords.lng : lng;

    final bloc = context.read<CarpoolOfferRideBloc>();

    if (_isEditingFrom) {
      _fromController.text = chosen;
      _fromLat = resolvedLat;
      _fromLng = resolvedLng;
      bloc.add(CarpoolOfferFromChanged(chosen, lat: resolvedLat, lng: resolvedLng));
      if (_toController.text.trim().isEmpty ||
          _toController.text.trim().toLowerCase() == chosen.toLowerCase()) {
        _toFocus.requestFocus();
        setState(() => _isSearching = true);
      } else {
        FocusScope.of(context).unfocus();
        setState(() => _isSearching = false);
      }
    } else {
      _toController.text = chosen;
      _toLat = resolvedLat;
      _toLng = resolvedLng;
      bloc.add(CarpoolOfferToChanged(chosen, lat: resolvedLat, lng: resolvedLng));
      FocusScope.of(context).unfocus();
      setState(() => _isSearching = false);
    }
  }

  void _onSwap(CarpoolOfferRideBloc bloc) {
    final tempText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tempText;

    final tempLat = _fromLat;
    final tempLng = _fromLng;
    _fromLat = _toLat;
    _fromLng = _toLng;
    _toLat = tempLat;
    _toLng = tempLng;

    bloc.add(const CarpoolOfferSwapPressed());

    if (_isSearching) {
      final activeQuery = _isEditingFrom
          ? _fromController.text
          : _toController.text;
      _triggerSearch(activeQuery);
    }
  }

  void _onUseCurrentLocation() {
    final bloc = context.read<CarpoolOfferRideBloc>();
    const loc = 'Current Location';
    _fromController.text = loc;
    _fromLat = 17.3850;
    _fromLng = 78.4867;
    bloc.add(const CarpoolOfferFromChanged(loc, lat: 17.3850, lng: 78.4867));
    _toFocus.requestFocus();
    setState(() => _isSearching = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarpoolOfferRideBloc, CarpoolOfferRideState>(
      builder: (context, s) {
        final bloc = context.read<CarpoolOfferRideBloc>();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FD),
          body: SafeArea(
            child: Column(
              children: [
                // ── 1. Top App Bar (Rapido style header) ────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isSearching) {
                            FocusScope.of(context).unfocus();
                            setState(() => _isSearching = false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
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
                      const Expanded(
                        child: Text(
                          'Set Pick-up & Drop Route',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Swap shortcut in app bar
                      GestureDetector(
                        onTap: () => _onSwap(bloc),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EEFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: Color(0xFF3815D8),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 2. Rapido-Style Dual From/To Search Container ───────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE2DCF9),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B3BF5).withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Pick-up (From) Input Row ────────────────────
                            Row(
                              children: [
                                // Green Dot Indicator
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF16A34A,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.circle,
                                    color: Color(0xFF16A34A),
                                    size: 11,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PICK-UP LOCATION',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B658C),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      TextField(
                                        controller: _fromController,
                                        focusNode: _fromFocus,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF140D43),
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onTap: () {
                                          setState(() {
                                            _isEditingFrom = true;
                                            _isSearching = true;
                                          });
                                          _triggerSearch(_fromController.text);
                                        },
                                        onChanged: (text) {
                                          setState(() {
                                            _isEditingFrom = true;
                                            _isSearching = true;
                                          });
                                          _triggerSearch(text);
                                        },
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search pickup city or area...',
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
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_fromController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _fromController.clear();
                                      setState(() => _isSearching = true);
                                      _triggerSearch('');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF9E98BE),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 36),
                              ],
                            ),

                            // ── Connector Line / Divider ────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 2,
                                    height: 18,
                                    color: const Color(0xFFD6CEF8),
                                  ),
                                  const SizedBox(width: 20),
                                  const Expanded(
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFEDE8FF),
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                ],
                              ),
                            ),

                            // ── Drop-off (To) Input Row ─────────────────────
                            Row(
                              children: [
                                // Red Pin Indicator
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DROP-OFF LOCATION',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B658C),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      TextField(
                                        controller: _toController,
                                        focusNode: _toFocus,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF140D43),
                                        ),
                                        textInputAction: TextInputAction.done,
                                        onTap: () {
                                          setState(() {
                                            _isEditingFrom = false;
                                            _isSearching = true;
                                          });
                                          _triggerSearch(_toController.text);
                                        },
                                        onChanged: (text) {
                                          setState(() {
                                            _isEditingFrom = false;
                                            _isSearching = true;
                                          });
                                          _triggerSearch(text);
                                        },
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search drop city or town...',
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
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_toController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _toController.clear();
                                      setState(() => _isSearching = true);
                                      _triggerSearch('');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF9E98BE),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 36),
                              ],
                            ),
                          ],
                        ),

                        // ── Floating Circular Swap Button ───────────────────
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _onSwap(bloc),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEBE6FC),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF5B3BF5,
                                    ).withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: Color(0xFF3815D8),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 3. Quick Shortcuts (Current Location & Map) ─────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _onUseCurrentLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EEFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF3815D8),
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Current Location',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF3815D8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Map selection is active'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Choose on Map',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF140D43),
                                    ),
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

                const Divider(height: 1, color: Color(0xFFEDE8FF)),

                // ── 4. Main Content: Google Places Autocomplete ──
                Expanded(
                  child:
                      BlocBuilder<
                        PlacesAutocompleteBloc,
                        PlacesAutocompleteState
                      >(
                        builder: (context, state) {
                          if (_isSearching &&
                              state.status ==
                                  PlacesAutocompleteStatus.loading &&
                              state.predictions.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF3815D8),
                              ),
                            );
                          }

                          if (_isSearching && state.predictions.isNotEmpty) {
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: state.predictions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 56,
                                endIndent: 16,
                                color: Color(0xFFF1EEFC),
                              ),
                              itemBuilder: (context, index) {
                                return _buildPredictionTile(
                                  state.predictions[index],
                                );
                              },
                            );
                          }

                          // Default view or when query is empty: Display clean search prompt with Current Location option
                          return _buildEmptySearchPrompt();
                        },
                      ),
                ),

                // ── 5. Bottom "Confirm Route" Bar ───────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5428E8), Color(0xFF240DA2)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4C1CDD).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () {
                          final f = _fromController.text.trim();
                          final t = _toController.text.trim();
                          if (f.isEmpty ||
                              t.isEmpty ||
                              f.toLowerCase() == t.toLowerCase()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter two different pickup & drop locations',
                                ),
                              ),
                            );
                            return;
                          }
                          final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
                            f,
                            preferredLat: _fromLat ?? (f == s.from && s.fromLat != 0.0 ? s.fromLat : null),
                            preferredLng: _fromLng ?? (f == s.from && s.fromLng != 0.0 ? s.fromLng : null),
                            defaultLat: s.fromLat,
                            defaultLng: s.fromLng,
                          );
                          final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
                            t,
                            preferredLat: _toLat ?? (t == s.to && s.toLat != 0.0 ? s.toLat : null),
                            preferredLng: _toLng ?? (t == s.to && s.toLng != 0.0 ? s.toLng : null),
                            defaultLat: s.toLat,
                            defaultLng: s.toLng,
                          );
                          bloc.add(CarpoolOfferFromChanged(f, lat: originCoords.lat, lng: originCoords.lng));
                          bloc.add(CarpoolOfferToChanged(t, lat: destCoords.lat, lng: destCoords.lng));
                          Navigator.of(context).pop();
                        },
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Confirm Route',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
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
        );
      },
    );
  }

  Widget _buildPredictionTile(PlacePredictionEntity place) {
    final type = CarpoolDistanceCalculator.classifyType(
      place.mainText,
      place.secondaryText,
    );
    final isVillage = type.toLowerCase().contains('village');
    final isTown = type.toLowerCase().contains('town');
    final geo = CarpoolDistanceCalculator.findGeo(
      place.mainText.isNotEmpty ? place.mainText : place.description,
    );
    final lat = place.lat ?? geo?.lat;
    final lng = place.lng ?? geo?.lng;
    final coordStr = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(3)}°N, ${lng.toStringAsFixed(3)}°E'
        : null;

    return InkWell(
      onTap: () => _onPlaceSelected(place),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isVillage
                    ? const Color(0xFFDCFCE7)
                    : (isTown
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFF1EEFC)),
                borderRadius: BorderRadius.circular(10),
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
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          place.mainText.isNotEmpty
                              ? place.mainText
                              : place.description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ),
                      if (coordStr != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EEFC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            coordStr,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3815D8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
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
                          place.secondaryText.isNotEmpty
                              ? place.secondaryText
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
            const Icon(
              Icons.north_west_rounded,
              size: 16,
              color: Color(0xFFB4AFD0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchPrompt() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      physics: const BouncingScrollPhysics(),
      children: [
        // "Use Current Location" Quick Action Card
        InkWell(
          onTap: _onUseCurrentLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8FF), width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06140D43),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
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
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3815D8),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Detect GPS coordinates automatically',
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
        const SizedBox(height: 48),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EEFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF3815D8),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditingFrom
                    ? 'Search pick-up location'
                    : 'Search drop-off location',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF140D43),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter an area, landmark, or address to search',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B658C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
