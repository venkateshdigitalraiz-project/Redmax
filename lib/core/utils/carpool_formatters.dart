import 'package:intl/intl.dart';

class CarpoolFormatters {
  CarpoolFormatters._();

  static String date(DateTime d) => DateFormat('EEE, MMM dd, yyyy').format(d);
  static String time(DateTime d) => DateFormat('hh:mm a').format(d);
  static String headline(DateTime d) =>
      DateFormat('EEE, MMM dd • hh:mm a').format(d);
  static String shortDateTime(DateTime d) =>
      DateFormat('MMM dd, hh:mm a').format(d);

  static String rupee(num value, {bool withSign = false}) {
    final formatted =
        NumberFormat.decimalPattern('en_IN').format(value.abs().round());
    final sign = !withSign ? '' : (value < 0 ? '-' : '+');
    return '$sign₹$formatted';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
