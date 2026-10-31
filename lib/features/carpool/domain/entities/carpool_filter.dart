import 'package:equatable/equatable.dart';

/// Enum for sort/filter options on carpool rides.
enum CarpoolSortBy { priceAsc, priceDsc, earliest, rating }

/// Filter entity applied to the carpool ride list.
class CarpoolFilter extends Equatable {
  final CarpoolSortBy sortBy;
  final double? maxPrice;
  final int minSeats;

  const CarpoolFilter({
    this.sortBy = CarpoolSortBy.priceAsc,
    this.maxPrice,
    this.minSeats = 1,
  });

  CarpoolFilter copyWith({
    CarpoolSortBy? sortBy,
    double? maxPrice,
    bool clearMaxPrice = false,
    int? minSeats,
  }) {
    return CarpoolFilter(
      sortBy: sortBy ?? this.sortBy,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minSeats: minSeats ?? this.minSeats,
    );
  }

  @override
  List<Object?> get props => [sortBy, maxPrice, minSeats];
}
