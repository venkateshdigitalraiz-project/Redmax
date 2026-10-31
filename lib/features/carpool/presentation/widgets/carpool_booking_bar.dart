import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';

/// Sticky bottom bar shown on the ride detail page with total price and booking button.
class CarpoolBookingBar extends StatelessWidget {
  final double pricePerSeat;
  final int selectedSeats;
  final int maxSeats;
  final bool isBooking;
  final VoidCallback onBook;
  final ValueChanged<int> onSeatsChanged;

  const CarpoolBookingBar({
    super.key,
    required this.pricePerSeat,
    required this.selectedSeats,
    required this.maxSeats,
    required this.isBooking,
    required this.onBook,
    required this.onSeatsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = (pricePerSeat * selectedSeats);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderLight : AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Fare',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '₹${pricePerSeat.toStringAsFixed(0)} × $selectedSeats seat${selectedSeats > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Seat stepper
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _stepperButton(
                  icon: Icons.remove_rounded,
                  enabled: selectedSeats > 1,
                  isDark: isDark,
                  onTap: () => onSeatsChanged(selectedSeats - 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$selectedSeats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add_rounded,
                  enabled: selectedSeats < maxSeats,
                  isDark: isDark,
                  onTap: () => onSeatsChanged(selectedSeats + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Book button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isBooking ? null : onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
              : AppColors.textTertiary,
        ),
      ),
    );
  }
}
