import 'package:intl/intl.dart';

class PartyFormatters {
  PartyFormatters._();

  static String date(DateTime d) => DateFormat('EEE, MMM dd, yyyy').format(d);

  static String rupee(num value) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';

  static String reviews(int count) {
    if (count >= 1000) {
      final k = (count / 1000).toStringAsFixed(1).replaceAll('.0', '');
      return '${k}k reviews';
    }
    return '$count reviews';
  }

  static String guests(int n) => '$n Guests';

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
