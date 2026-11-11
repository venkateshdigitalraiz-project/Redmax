import 'package:flutter/material.dart';

import '../pages/rapido_place_search_page.dart';

/// Helper function to open the Rapido-style Google Places search anywhere in Carpool.
Future<CarpoolPlaceResult?> carpoolSelectLocation(
  BuildContext context, {
  required String title,
  String initialValue = '',
  bool isPickup = true,
  String apiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU',
}) {
  return RapidoPlaceSearchPage.show(
    context,
    title: title,
    initialValue: initialValue,
    isPickup: isPickup,
    apiKey: apiKey,
  );
}

/// Reusable From/To Selector Component that can be placed inside any Card or Container across Carpool.
/// Includes:
/// - "From" row with blue location pin and place title.
/// - Divider.
/// - "To" row with red location pin and place title.
/// - Floating circular Swap button.
class CarpoolFromToSelector extends StatelessWidget {
  final String from;
  final String to;
  final ValueChanged<String>? onFromChanged;
  final ValueChanged<String>? onToChanged;
  final void Function(String name, double? lat, double? lng)? onFromLocationChanged;
  final void Function(String name, double? lat, double? lng)? onToLocationChanged;
  final VoidCallback? onSwap;
  final bool showSwapButton;
  final String fromLabel;
  final String toLabel;
  final String fromSearchTitle;
  final String toSearchTitle;
  final String apiKey;

  const CarpoolFromToSelector({
    super.key,
    required this.from,
    required this.to,
    this.onFromChanged,
    this.onToChanged,
    this.onFromLocationChanged,
    this.onToLocationChanged,
    this.onSwap,
    this.showSwapButton = true,
    this.fromLabel = 'From',
    this.toLabel = 'To',
    this.fromSearchTitle = 'Search Pickup Location',
    this.toSearchTitle = 'Search Drop Location',
    this.apiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU',
  });

  Future<void> _pickFrom(BuildContext context) async {
    final selected = await carpoolSelectLocation(
      context,
      title: fromSearchTitle,
      initialValue: from,
      isPickup: true,
      apiKey: apiKey,
    );
    if (selected != null && selected.name.trim().isNotEmpty) {
      final name = selected.name.trim();
      if (onFromLocationChanged != null) {
        onFromLocationChanged!(name, selected.lat, selected.lng);
      } else {
        onFromChanged?.call(name);
      }
    }
  }

  Future<void> _pickTo(BuildContext context) async {
    final selected = await carpoolSelectLocation(
      context,
      title: toSearchTitle,
      initialValue: to,
      isPickup: false,
      apiKey: apiKey,
    );
    if (selected != null && selected.name.trim().isNotEmpty) {
      final name = selected.name.trim();
      if (onToLocationChanged != null) {
        onToLocationChanged!(name, selected.lat, selected.lng);
      } else {
        onToChanged?.call(name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "From" Row
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickFrom(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF2E15D0),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fromLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            from.trim().isNotEmpty ? from : 'Current Location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: from.trim().isNotEmpty
                                  ? const Color(0xFF140D43)
                                  : const Color(0xFF3815D8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showSwapButton) const SizedBox(width: 44),
                  ],
                ),
              ),
            ),

            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1EEFC),
            ),

            // "To" Row
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickTo(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            to.trim().isNotEmpty ? to : 'Enter Destination',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: to.trim().isNotEmpty
                                  ? const Color(0xFF140D43)
                                  : const Color(0xFF9E98BE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showSwapButton) const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Floating Circular Swap Button
        if (showSwapButton && onSwap != null)
          Positioned(
            right: 2,
            child: GestureDetector(
              onTap: onSwap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEBE6FC),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B3BF5).withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF3815D8),
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Standalone Reusable Route Selector Card with border and shadow.
class CarpoolRouteSelectorCard extends StatelessWidget {
  final String from;
  final String to;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback? onSwap;
  final bool showSwapButton;
  final String fromLabel;
  final String toLabel;
  final String fromSearchTitle;
  final String toSearchTitle;
  final String apiKey;

  const CarpoolRouteSelectorCard({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    this.onSwap,
    this.showSwapButton = true,
    this.fromLabel = 'From',
    this.toLabel = 'To',
    this.fromSearchTitle = 'Search Pickup Location',
    this.toSearchTitle = 'Search Drop Location',
    this.apiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CarpoolFromToSelector(
        from: from,
        to: to,
        onFromChanged: onFromChanged,
        onToChanged: onToChanged,
        onSwap: onSwap,
        showSwapButton: showSwapButton,
        fromLabel: fromLabel,
        toLabel: toLabel,
        fromSearchTitle: fromSearchTitle,
        toSearchTitle: toSearchTitle,
        apiKey: apiKey,
      ),
    );
  }
}
