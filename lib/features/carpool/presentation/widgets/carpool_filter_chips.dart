import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_filter.dart';

/// Horizontal scrollable row of filter chips for carpool rides.
class CarpoolFilterChips extends StatelessWidget {
  final CarpoolFilter currentFilter;
  final ValueChanged<CarpoolFilter> onFilterChanged;

  const CarpoolFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = <_ChipData>[
      _ChipData(
        label: 'All',
        sortBy: null,
        icon: Icons.apps_rounded,
      ),
      _ChipData(
        label: 'Price ↑',
        sortBy: CarpoolSortBy.priceAsc,
        icon: Icons.trending_up_rounded,
      ),
      _ChipData(
        label: 'Price ↓',
        sortBy: CarpoolSortBy.priceDsc,
        icon: Icons.trending_down_rounded,
      ),
      _ChipData(
        label: 'Earliest',
        sortBy: CarpoolSortBy.earliest,
        icon: Icons.access_time_rounded,
      ),
      _ChipData(
        label: 'Top Rated',
        sortBy: CarpoolSortBy.rating,
        icon: Icons.star_rounded,
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = chip.sortBy == null
              ? _isAllSelected()
              : currentFilter.sortBy == chip.sortBy;

          return GestureDetector(
            onTap: () {
              if (chip.sortBy == null) {
                // "All" – reset to default sort
                onFilterChanged(
                  currentFilter.copyWith(sortBy: CarpoolSortBy.priceAsc),
                );
              } else {
                onFilterChanged(currentFilter.copyWith(sortBy: chip.sortBy));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? AppColors.darkBorderLight
                          : AppColors.border),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip.icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isAllSelected() {
    // "All" chip is effectively just the default sort (priceAsc) with no additional filters
    return currentFilter.sortBy == CarpoolSortBy.priceAsc &&
        currentFilter.maxPrice == null &&
        currentFilter.minSeats == 1;
  }
}

class _ChipData {
  final String label;
  final CarpoolSortBy? sortBy;
  final IconData icon;

  const _ChipData({
    required this.label,
    required this.sortBy,
    required this.icon,
  });
}
