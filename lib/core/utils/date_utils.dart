import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date, [String locale = 'en']) {
    try {
      final formatter = DateFormat.yMd(locale);
      return formatter.format(date);
    } catch (e) {
      // Fallback to English if locale is not supported
      final formatter = DateFormat.yMd('en');
      return formatter.format(date);
    }
  }

  static String formatMonthYear(DateTime date, [String locale = 'en']) {
    try {
      final formatter = DateFormat.yMMM(locale);
      return formatter.format(date);
    } catch (e) {
      // Fallback to English if locale is not supported
      final formatter = DateFormat.yMMM('en');
      return formatter.format(date);
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // New methods used in expense detail screen
  static String formatDetailDate(DateTime date, [String locale = 'en']) => formatDate(date, locale);
  
  static String formatTime(DateTime date, [String locale = 'en']) {
    try {
      final formatter = DateFormat.Hm(locale);
      return formatter.format(date);
    } catch (e) {
      // Fallback to manual formatting if locale is not supported
      return '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    }
  }
  
  static String formatFullDateTime(DateTime date, [String locale = 'en']) {
    try {
      final formatter = DateFormat.yMd(locale).add_Hm();
      return formatter.format(date);
    } catch (e) {
      // Fallback to English if locale is not supported
      final formatter = DateFormat.yMd('en').add_Hm();
      return formatter.format(date);
    }
  }
  
  static String formatDayOfWeek(DateTime date, [String locale = 'en']) {
    try {
      final formatter = DateFormat.EEEE(locale);
      return formatter.format(date);
    } catch (e) {
      // Fallback to English if locale is not supported
      final formatter = DateFormat.EEEE('en');
      return formatter.format(date);
    }
  }
}