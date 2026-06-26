import 'package:intl/intl.dart';

class DateFormatter {
  static String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static String formatTimeOnly(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
