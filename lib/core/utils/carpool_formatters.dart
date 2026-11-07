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

  /// Formats a DateTime into UTC ISO-8601 format: yyyy-MM-ddTHH:mm:ss.000Z
  static String toUtcIso(DateTime d) {
    final utc = d.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    final ms = utc.millisecond.toString().padLeft(3, '0');
    return '$y-$m-${day}T$h:$min:$s.${ms}Z';
  }
}
